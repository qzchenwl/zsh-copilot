#!/usr/bin/env zsh

# Default key binding
(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

# Configuration options
(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

# Selection state variables
typeset -g ZSH_COPILOT_SUGGESTIONS=()
typeset -g ZSH_COPILOT_SELECTED_INDEX=0
typeset -g ZSH_COPILOT_SELECTION_MODE=false
typeset -g ZSH_COPILOT_ORIGINAL_BUFFER=""

# Helper function to safely clear autosuggestions
function _safe_zsh_autosuggest_clear() {
    if declare -f _zsh_autosuggest_clear > /dev/null; then
        _zsh_autosuggest_clear
    fi
}

# Helper function to safely show autosuggestions
function _safe_zsh_autosuggest_suggest() {
    if declare -f _zsh_autosuggest_suggest > /dev/null; then
        _zsh_autosuggest_suggest "$1"
    else
        # Fallback: display the suggestion manually
        zle -M "Suggestion: $1"
    fi
}

# Check for OpenAI API key
if [[ -z "$ZSH_COPILOT_OPENAI_API_KEY" ]]; then
    echo "Please set ZSH_COPILOT_OPENAI_API_KEY environment variable."
    return 1
fi

# System prompt
if [[ -z "$ZSH_COPILOT_SYSTEM_PROMPT" ]]; then
read -r -d '' ZSH_COPILOT_SYSTEM_PROMPT <<- EOM
  You are a shell command assistant. When given a partial or complete shell command input, you should provide 2-4 relevant command suggestions with explanations using the provide_command_suggestions function.

  Rules for suggestions:
  1. Provide 2-4 suggestions, ordered by relevance
  2. For partial input, try to complete it first, then suggest alternatives
  3. Each suggestion should have a clear, brief description (max 60 characters)
  4. Commands should be complete and ready to execute
EOM
fi

if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
    touch /tmp/zsh-copilot.log
fi

function _fetch_suggestions() {
    local data
    local response
    local message
        # Use jq to properly construct JSON payload with function calling
        data=$(jq -n \
            --arg model "gpt-4.1" \
            --arg prompt "$full_prompt" \
            --arg input "$input" \
            '{
                model: $model,
                messages: [
                    {
                        role: "system",
                        content: $prompt
                    },
                    {
                        role: "user", 
                        content: $input
                    }
                ],
                tools: [
                    {
                        type: "function",
                        function: {
                            name: "provide_command_suggestions",
                            description: "Provide shell command suggestions with explanations",
                            parameters: {
                                type: "object",
                                properties: {
                                                                    suggestions: {
                                    type: "array",
                                    items: {
                                        type: "object",
                                        properties: {
                                            command: {
                                                type: "string",
                                                description: "The complete shell command"
                                            },
                                            description: {
                                                type: "string",
                                                description: "Brief explanation of what the command does"
                                            }
                                        },
                                        required: ["command", "description"]
                                    }
                                }
                                },
                                required: ["suggestions"]
                            }
                        }
                    }
                ],
                tool_choice: {
                    type: "function",
                    function: {
                        name: "provide_command_suggestions"
                    }
                }
            }')
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "$data" >> /tmp/zsh-copilot.log
        fi
        response=$(curl "https://${openai_api_url}/api/v1/chat/completions" \
            --silent \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ZSH_COPILOT_OPENAI_API_KEY" \
            -d "$data")
        response_code=$?

        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Called OpenAI API\",\"input\":\"$input\",\"response\":\"$response\",\"response_code\":\"$response_code\"}" >> /tmp/zsh-copilot.log
        fi

        if [[ $response_code -ne 0 ]]; then
            echo "Error fetching suggestions from the OpenAI API. Please check your API key and try again." > /tmp/.zsh_copilot_error
            return 1
        fi

        # Debug: Log raw response for troubleshooting
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "$response" >> /tmp/zsh-copilot.log
        fi

        # Check if response is valid JSON and extract message from tool calls
        if echo "$response" | jq empty 2>/dev/null; then
            # Check if there are tool calls (check if array exists and has elements)
            local has_tool_calls=$(echo "$response" | jq -r '.choices[0].message.tool_calls | type == "array" and length > 0')
            if [[ "$has_tool_calls" == "true" ]]; then
                if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
                    echo "{\"date\":\"$(date)\",\"log\":\"Tool calls found\"}" >> /tmp/zsh-copilot.log
                fi
                # Extract function call arguments
                message=$(echo "$response" | jq -r '.choices[0].message.tool_calls[0].function.arguments')
                if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
                    echo "{\"date\":\"$(date)\",\"log\":\"Extracted arguments\",\"arguments_preview\":\"$(echo "$message" | head -c 200)\",\"full_length\":\"${#message}\"}" >> /tmp/zsh-copilot.log
                fi
                if [[ -z "$message" || "$message" == "null" ]]; then
                    echo "Error: Empty function call arguments" > /tmp/.zsh_copilot_error
                    return 1
                fi
            else
                # Fallback to regular content if no tool calls
                message=$(echo "$response" | jq -r '.choices[0].message.content // empty')
                if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
                    echo "{\"date\":\"$(date)\",\"log\":\"No tool calls, using content\",\"content_preview\":\"$(echo "$message" | head -c 200)\"}" >> /tmp/zsh-copilot.log
                fi
                if [[ -z "$message" || "$message" == "null" ]]; then
                    echo "Error: Empty or invalid response from API" > /tmp/.zsh_copilot_error
                    return 1
                fi
            fi
        else
            echo "Error: Invalid JSON response from API" > /tmp/.zsh_copilot_error
            return 1
        fi

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"About to write message to file\",\"message_length\":\"${#message}\"}" >> /tmp/zsh-copilot.log
    fi
    
    # Validate message is valid JSON before writing
    if ! echo "$message" | jq empty 2>/dev/null; then
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Message is not valid JSON\",\"message\":\"$(echo "$message" | head -c 200)\"}" >> /tmp/zsh-copilot.log
        fi
        echo "Error: Invalid JSON format in function arguments" > /tmp/.zsh_copilot_error
        return 1
    fi
    
    # Use printf for safer writing to handle special characters
    printf "%s\n" "$message" > /tmp/zsh_copilot_suggestion || {
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Failed to write message to file\",\"error\":\"$?\"}" >> /tmp/zsh-copilot.log
        fi
        echo "Error: Failed to write suggestion data" > /tmp/.zsh_copilot_error
        return 1
    }
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Successfully wrote message to file\"}" >> /tmp/zsh-copilot.log
    fi
}

# Function to display suggestion selection interface
function _display_suggestions() {
    local suggestions_json="$1"
    local selected_index="$2"
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Display suggestions called\",\"selected_index\":\"$selected_index\"}" >> /tmp/zsh-copilot.log
    fi
    
    # Build multi-line status message with # separator
    local message="AI Suggestions (↑/↓ navigate, Enter select, ESC cancel):"
    local i=0
    
    while IFS= read -r suggestion; do
        local command=$(echo "$suggestion" | jq -r '.command')
        local description=$(echo "$suggestion" | jq -r '.description')
        
        if [[ $i -eq $selected_index ]]; then
            message+=$'\n'"▶ $((i+1)). $command # $description"
        else
            message+=$'\n'"  $((i+1)). $command # $description"
        fi
        
        ((i++))
    done < <(echo "$suggestions_json" | jq -c '.suggestions[]')
    
    # Use zle -M for stable display
    zle -M "$message"
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Display completed\",\"suggestions_shown\":\"$i\"}" >> /tmp/zsh-copilot.log
    fi
}

# Function to handle suggestion navigation
function _handle_suggestion_navigation() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" != "true" ]]; then
        return 1
    fi
    
    local key="$1"
    local suggestions_count=${#ZSH_COPILOT_SUGGESTIONS[@]}
    
    case "$key" in
        "down"|"ctrl_n")
            ZSH_COPILOT_SELECTED_INDEX=$(( (ZSH_COPILOT_SELECTED_INDEX + 1) % suggestions_count ))
            ;;
        "up"|"ctrl_p")
            ZSH_COPILOT_SELECTED_INDEX=$(( (ZSH_COPILOT_SELECTED_INDEX - 1 + suggestions_count) % suggestions_count ))
            ;;
        *)
            return 1
            ;;
    esac
    
    # Update buffer with selected command (ZSH arrays are 1-based)
    local selected_suggestion="${ZSH_COPILOT_SUGGESTIONS[$((ZSH_COPILOT_SELECTED_INDEX + 1))]}"
    BUFFER="$selected_suggestion"
    CURSOR=${#BUFFER}
    
    # Redisplay interface with new selection
    _display_suggestions "$(cat /tmp/zsh_copilot_suggestion)" "$ZSH_COPILOT_SELECTED_INDEX"
}

# Function to exit selection mode
function _exit_selection_mode() {
    # Clear the status message
    zle -M ""
    
    # Reset selection mode variables
    ZSH_COPILOT_SELECTION_MODE=false
    ZSH_COPILOT_SUGGESTIONS=()
    ZSH_COPILOT_SELECTED_INDEX=0
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Exited selection mode\"}" >> /tmp/zsh-copilot.log
    fi
    
    zle redisplay
}

# Navigation key bindings for selection mode
function _copilot_down() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "down"
    else
        zle down-line-or-history
    fi
}

function _copilot_up() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "up"
    else
        zle up-line-or-history
    fi
}

function _copilot_ctrl_n() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "ctrl_n"
    else
        zle down-line-or-history
    fi
}

function _copilot_ctrl_p() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "ctrl_p"
    else
        zle up-line-or-history
    fi
}

function _copilot_accept_line() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle accept-line
}

function _copilot_escape() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        # Restore original buffer and exit selection mode
        BUFFER="$ZSH_COPILOT_ORIGINAL_BUFFER"
        CURSOR=${#BUFFER}
        _exit_selection_mode
    else
        # Default escape behavior
        zle send-break
    fi
}

# Handle other keys that should exit selection mode
function _copilot_self_insert() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle self-insert
}

function _copilot_backward_delete_char() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle backward-delete-char
}

function _copilot_delete_char() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle delete-char
}

# Handle left/right arrows to exit selection and allow normal cursor movement
function _copilot_forward_char() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle forward-char
}

function _copilot_backward_char() {
    if [[ "$ZSH_COPILOT_SELECTION_MODE" == "true" ]]; then
        _exit_selection_mode
    fi
    zle backward-char
}


function _show_loading_animation() {
    local pid=$1
    local interval=0.1
    local animation_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=1

    cleanup() {
      kill $pid
      echo -ne "\e[?25h"
    }
    trap cleanup SIGINT
    
    while kill -0 $pid 2>/dev/null; do
        # Display current animation frame
        zle -R "${animation_chars[i]}"

        # Update index, make sure it starts at 1
        i=$(( (i + 1) % ${#animation_chars[@]} ))

        if [[ $i -eq 0 ]]; then
            i=1
        fi
        
        sleep $interval
    done

    echo -ne "\e[?25h"
    trap - SIGINT
}

function _suggest_ai() {
    #### Prepare environment
    local openai_api_url=${ZSH_COPILOT_OPENAI_API_URL:-"api.openai.com"}

    local context_info=""
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local system

        if [[ "$OSTYPE" == "darwin"* ]]; then
            system="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
        else 
            system="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
        fi

        context_info="Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $system"
    fi

    ##### Get input
    rm -f /tmp/zsh_copilot_suggestion
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')

    _safe_zsh_autosuggest_clear

    local full_prompt=$(echo "$ZSH_COPILOT_SYSTEM_PROMPT $context_info" | tr -d '\n')

    ##### Fetch message
    read < <(_fetch_suggestions & echo $!)
    local pid=$REPLY

    _show_loading_animation $pid
    local response_code=$?

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Loading animation finished\",\"input\":\"$input\",\"response_code\":\"$response_code\"}" >> /tmp/zsh-copilot.log
    fi

    if [[ ! -f /tmp/zsh_copilot_suggestion ]]; then
        _safe_zsh_autosuggest_clear
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Suggestion file not found\"}" >> /tmp/zsh-copilot.log
        fi
        local error_msg
        if [[ -f /tmp/.zsh_copilot_error ]]; then
            error_msg=$(cat /tmp/.zsh_copilot_error)
        else
            error_msg="No suggestion available at this time. Please try again later."
        fi
        zle -M "$error_msg"
        return 1
    fi

    local message=$(cat /tmp/zsh_copilot_suggestion)
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Read message from file\",\"message_length\":\"${#message}\",\"first_100_chars\":\"$(echo "$message" | head -c 100)\"}" >> /tmp/zsh-copilot.log
    fi

    ##### Process JSON response

    # Validate JSON format
    if ! echo "$message" | jq empty 2>/dev/null; then
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Invalid JSON format in main function\",\"message_preview\":\"$(echo "$message" | head -c 200)\"}" >> /tmp/zsh-copilot.log
            echo "{\"date\":\"$(date)\",\"log\":\"Raw message for debugging\",\"message\":\"$message\"}" >> /tmp/zsh-copilot.log
        fi
        zle -M "Error: Invalid JSON response from AI"
        return 1
    fi

    # Parse suggestions
    local suggestions_array=()
    while IFS= read -r suggestion; do
        local command=$(echo "$suggestion" | jq -r '.command')
        suggestions_array+=("$command")
    done < <(echo "$message" | jq -c '.suggestions[]')

    if [[ ${#suggestions_array[@]} -eq 0 ]]; then
        zle -M "No suggestions available"
        return 1
    fi

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Suggestions parsed\",\"input\":\"$input\",\"suggestions_count\":\"${#suggestions_array[@]}\",\"message_content\":\"$(echo "$message" | head -c 200)\"}" >> /tmp/zsh-copilot.log
    fi

    ##### Enter selection mode and display suggestions

    ZSH_COPILOT_SELECTION_MODE=true
    ZSH_COPILOT_SUGGESTIONS=("${suggestions_array[@]}")
    ZSH_COPILOT_SELECTED_INDEX=0
    ZSH_COPILOT_ORIGINAL_BUFFER="$BUFFER"

    # Set the first suggestion as current buffer (ZSH arrays are 1-based)
    BUFFER="${suggestions_array[1]}"
    CURSOR=${#BUFFER}

    # Display the selection interface
    _display_suggestions "$message" 0
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Suggestions displayed with zle -M\"}" >> /tmp/zsh-copilot.log
    fi
}

function zsh-copilot() {
    echo "ZSH Copilot is now active. Press $ZSH_COPILOT_KEY to get suggestions."
    echo ""
    echo "Usage:"
    echo "    1. Press $ZSH_COPILOT_KEY to get AI suggestions"
    echo "    2. Use ↑/↓ or Ctrl+P/Ctrl+N to navigate between suggestions"
    echo "    3. Press Enter to accept selected suggestion"
    echo "    4. Press ESC to cancel and restore original input"
    echo "    5. Press any other key (letters, arrows, etc.) to exit and continue editing"
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_KEY: Key to press to get suggestions (default: ^z, value: $ZSH_COPILOT_KEY)."
    echo "    - ZSH_COPILOT_SEND_CONTEXT: If true, send context information to AI (default: true, value: $ZSH_COPILOT_SEND_CONTEXT)."
    echo "    - ZSH_COPILOT_OPENAI_API_KEY: OpenAI API key (required)."
    echo "    - ZSH_COPILOT_OPENAI_API_URL: OpenAI API base URL (default: api.openai.com)."
    echo "    - ZSH_COPILOT_SYSTEM_PROMPT: System prompt to use for the AI model (uses a built-in prompt by default)."
    echo "    - ZSH_COPILOT_DEBUG: Enable debug logging to /tmp/zsh-copilot.log (default: false)."
}

zle -N _suggest_ai
bindkey "$ZSH_COPILOT_KEY" _suggest_ai

# Bind navigation keys for suggestion selection
zle -N _copilot_down
zle -N _copilot_up
zle -N _copilot_ctrl_n
zle -N _copilot_ctrl_p
zle -N _copilot_accept_line

zle -N _copilot_escape
zle -N _copilot_self_insert
zle -N _copilot_backward_delete_char
zle -N _copilot_delete_char
zle -N _copilot_forward_char
zle -N _copilot_backward_char

bindkey "^[[B" _copilot_down      # Down arrow
bindkey "^[[A" _copilot_up        # Up arrow  
bindkey "^[[C" _copilot_forward_char    # Right arrow
bindkey "^[[D" _copilot_backward_char   # Left arrow
bindkey "^N" _copilot_ctrl_n      # Ctrl+N
bindkey "^P" _copilot_ctrl_p      # Ctrl+P
bindkey "^M" _copilot_accept_line # Enter key
bindkey "^[" _copilot_escape      # ESC key
bindkey "^H" _copilot_backward_delete_char    # Backspace
bindkey "^?" _copilot_backward_delete_char    # Delete (some terminals)
bindkey "^[[3~" _copilot_delete_char          # Delete key


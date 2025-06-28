**NOTICE**: I'm slowly migrating my repositories to my own Git server. Please visit this repository at [https://git.myzel394.app/Myzel394/zsh-copilot](https://git.myzel394.app/Myzel394/zsh-copilot) for the latest updates.

# ZSH Copilot - Enhanced Multi-Option Version

An enhanced version of [zsh-copilot](https://github.com/Myzel394/zsh-copilot) with **multiple AI suggestions** and **interactive selection**.

## 🚀 Key Improvements Over Original

This fork transforms the original single-suggestion zsh-copilot into a **multi-option AI assistant** with enhanced user interaction:

### ✨ Major Features Added

#### 🎯 **Multiple AI Suggestions**
- **Original**: Returns only 1 command suggestion
- **Enhanced**: Provides 2-4 relevant command options to choose from
- Each suggestion includes both command and description

#### 🎮 **Interactive Selection Interface** 
- **Original**: Automatically inserts single suggestion
- **Enhanced**: Interactive menu for browsing options
  - `↑/↓` or `Ctrl+P/Ctrl+N` to navigate between suggestions
  - `Enter` to accept selected suggestion
  - `ESC` to cancel and restore original input
  - Any other key exits selection mode

#### 📺 **Improved Display**
- **Original**: Single line auto-completion
- **Enhanced**: Multi-line status display with clear formatting
  - Each suggestion on separate line
  - `▶` indicator for current selection
  - Command and description separated by `#`
  - Real-time command line updates

#### 🔧 **API & Technical Improvements**
- **Streamlined API Support**: Removed Anthropic, focused on OpenAI
- **Function Calling**: Uses OpenAI function calling for structured responses
- **Better Error Handling**: Enhanced JSON parsing and error messages
- **Improved Debugging**: More detailed logging for troubleshooting

## 📖 Usage

1. **Start typing a command** (e.g., `ffmpeg convert video`)
2. **Press `Ctrl+Z`** to get AI suggestions
3. **Navigate options** with `↑/↓` or `Ctrl+P/Ctrl+N`
4. **Watch command line update** in real-time as you navigate
5. **Press `Enter`** to accept or `ESC` to cancel

### Example Interface
```
AI Suggestions (↑/↓ navigate, Enter select, ESC cancel):
  1. ffmpeg -i input.mp4 -c:v libx264 output.mp4 # Convert video with H.264
▶ 2. ffmpeg -i input.mp4 -vf scale=1280:720 output.mp4 # Resize video to 720p  
  3. ffmpeg -i input.mp4 -c:a aac -b:a 128k output.mp4 # Convert audio to AAC
  4. ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 output.mp4 # Extract 30s clip
```

## 🛠 Installation

1. **Clone this repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/zsh-copilot-enhanced ~/.config/zsh-copilot
   ```

2. **Set your OpenAI API key**:
   ```bash
   export ZSH_COPILOT_OPENAI_API_KEY="your-api-key"
   ```

3. **Load the plugin** in your `.zshrc`:
   ```bash
   source ~/.config/zsh-copilot/zsh-copilot.plugin.zsh
   ```

## ⚙️ Configuration

```bash
# Key binding (default: Ctrl+Z)
export ZSH_COPILOT_KEY="^z"

# Include system context (default: true)
export ZSH_COPILOT_SEND_CONTEXT=true

# OpenAI API configuration
export ZSH_COPILOT_OPENAI_API_KEY="your-key"
export ZSH_COPILOT_OPENAI_API_URL="api.openai.com"  # optional

# Debug logging (default: false)
export ZSH_COPILOT_DEBUG=true  # Logs to /tmp/zsh-copilot.log
```

## 🔄 Changes from Original

### Removed Features
- ❌ Anthropic API support (simplified to OpenAI only)
- ❌ Single suggestion auto-completion
- ❌ Chinese language interface

### Added Features  
- ✅ Multi-option suggestion system (2-4 options)
- ✅ Interactive navigation with arrow keys
- ✅ Real-time command line preview
- ✅ Enhanced error handling and debugging
- ✅ Function calling for reliable JSON responses
- ✅ Improved display formatting with `#` separators
- ✅ English-only interface for international compatibility

### Technical Improvements
- 🔧 **Robust JSON Parsing**: Function calling ensures consistent response format
- 🔧 **Better Error Messages**: Clear feedback via `zle -M` status display
- 🔧 **ZSH Array Compatibility**: Fixed 1-based array indexing issues
- 🔧 **Enhanced Debugging**: Detailed logging with message validation

## 📋 TODO & Future Features

### 🎯 **Enhanced Context Awareness**
- [ ] **Command History Integration**: Include recent executed commands in AI context
- [ ] **Output Analysis**: Send previous command outputs to help AI understand current state
- [ ] **Error Context**: Include error messages from failed commands for better troubleshooting suggestions
- [ ] **Working Directory Context**: Enhanced directory-specific suggestions based on file types and project structure

### 🚀 **Advanced AI Features**
- [ ] **Multi-step Command Sequences**: AI suggests command pipelines and workflows
- [ ] **Personalized Suggestions**: Learn from user's command patterns and preferences
- [ ] **Smart Follow-up**: Context-aware suggestions based on previous command results
- [ ] **Error Recovery**: Automatic suggestions when commands fail

### 🎨 **UI/UX Improvements**
- [ ] **Color Themes**: Customizable color schemes for better terminal integration
- [ ] **Preview Mode**: Show expected command output before execution
- [ ] **Keyboard Shortcuts**: More navigation options (J/K vim-style, numbers for direct selection)
- [ ] **Smart Truncation**: Better handling of long commands in display

### 🔧 **Technical Enhancements**
- [ ] **Local AI Support**: Integration with local models (Ollama, etc.)
- [ ] **Caching System**: Cache frequent suggestions for faster response
- [ ] **Plugin Integration**: Better compatibility with other ZSH plugins
- [ ] **Performance Optimization**: Reduce latency and improve responsiveness

### 📊 **Analytics & Learning**
- [ ] **Usage Statistics**: Track which suggestions are most helpful
- [ ] **Success Rate Monitoring**: Learn from accepted vs rejected suggestions
- [ ] **Context Effectiveness**: Measure how command history improves suggestion quality

## 🤝 Contributing

This project builds upon the excellent foundation of [Myzel394's zsh-copilot](https://github.com/Myzel394/zsh-copilot). 

Feel free to submit issues and pull requests to further improve the multi-option AI experience! Priority areas for contribution:
- **Command History Integration** (highest priority)
- **Output Analysis Features**
- **UI/UX Improvements**
- **Performance Optimizations**

## 📄 License

Same as original project - see the [original repository](https://github.com/Myzel394/zsh-copilot) for license details.

## 🙏 Credits

- **Original Project**: [zsh-copilot by Myzel394](https://github.com/Myzel394/zsh-copilot)
- **Enhanced Version**: Multi-option interface and interactive features


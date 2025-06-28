# ZSH Copilot - Multi-Option AI Assistant

Enhanced version of [zsh-copilot](https://github.com/Myzel394/zsh-copilot) with **multiple AI suggestions** and **interactive selection**.

## ✨ Key Features

- **Multiple Suggestions**: Provides 2-4 relevant command options
- **Interactive Interface**: Navigate with `↑/↓` or `Ctrl+P/Ctrl+N`
- **Real-time Preview**: Command line updates as you navigate
- **Simple Controls**: `Enter` to select, `ESC` to cancel

## 🚀 Usage

1. Start typing a command (e.g., `ffmpeg convert video`)
2. Press `Ctrl+Z` to get AI suggestions
3. Use `↑/↓` to navigate options
4. Press `Enter` to confirm or `ESC` to cancel

### Interface Example
```
AI Suggestions (↑/↓ navigate, Enter select, ESC cancel):
  1. ffmpeg -i input.mp4 -c:v libx264 output.mp4 # Convert video with H.264
▶ 2. ffmpeg -i input.mp4 -vf scale=1280:720 output.mp4 # Resize video to 720p
  3. ffmpeg -i input.mp4 -c:a aac -b:a 128k output.mp4 # Convert audio to AAC
```

## 🛠 Installation

1. **Clone repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/zsh-copilot ~/.config/zsh-copilot
   ```

2. **Set API key**:
   ```bash
   export ZSH_COPILOT_OPENAI_API_KEY="your-api-key"
   ```

3. **Load plugin** (in `.zshrc`):
   ```bash
   source ~/.config/zsh-copilot/zsh-copilot.plugin.zsh
   ```

## ⚙️ Configuration

```bash
# Key binding (default: Ctrl+Z)
export ZSH_COPILOT_KEY="^z"

# OpenAI API configuration
export ZSH_COPILOT_OPENAI_API_KEY="your-key"
export ZSH_COPILOT_OPENAI_API_URL="api.openai.com"  # optional

# Include system context (default: true)
export ZSH_COPILOT_SEND_CONTEXT=true

# Debug logging (default: false)
export ZSH_COPILOT_DEBUG=true  # Logs to /tmp/zsh-copilot.log
```

## 🤝 Contributing

Feel free to submit issues and pull requests to improve this project!

## 🙏 Credits

- **Original Project**: [zsh-copilot by Myzel394](https://github.com/Myzel394/zsh-copilot)
- **Enhanced Version**: Added multi-option interface and interactive features

## 📄 License

Same as original project - see the [original repository](https://github.com/Myzel394/zsh-copilot) for license details.


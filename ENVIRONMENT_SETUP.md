# Environment Setup

This project uses environment variables to securely store API keys. Follow these steps to set up your development environment:

## 1. Create Environment File

Create a `.env` file in the project root with your actual API keys:

```bash
# Copy the template and add your real keys
cp .env .env.local
# Edit .env.local with your actual keys
```

Your `.env` file should look like this:
```
REPLICATE_API_KEY=your_actual_replicate_key_here
OPENROUTER_API_KEY=your_actual_openrouter_key_here
```

## 2. Xcode Configuration

The Xcode scheme is already configured to use these environment variables. The scheme file references:
- `$(REPLICATE_API_KEY)` 
- `$(OPENROUTER_API_KEY)`

## 3. Loading Environment Variables

### Option A: Manual Export (Current Setup)
Before running Xcode, export the variables in your terminal:
```bash
export REPLICATE_API_KEY="your_key_here"
export OPENROUTER_API_KEY="your_key_here"
open routine-apps.xcodeproj
```

### Option B: Using the Load Script
You can source the environment variables:
```bash
source load-env.sh
open routine-apps.xcodeproj
```

## 4. Accessing in Swift Code

In your Swift code, you can access these environment variables using:
```swift
let replicateKey = ProcessInfo.processInfo.environment["REPLICATE_API_KEY"]
let openRouterKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
```

## Security Notes

- Never commit `.env` files to git (they're in `.gitignore`)
- Environment variables are loaded at build/run time
- Keys are not embedded in the compiled binary when using environment variables
- For production builds, use Xcode build configurations or CI/CD environment variables

## Troubleshooting

If the app can't find the API keys:
1. Make sure your `.env` file exists and has the correct format
2. Ensure you've exported the variables before opening Xcode
3. Check that the Xcode scheme environment variables are set to `$(REPLICATE_API_KEY)` and `$(OPENROUTER_API_KEY)`
4. Restart Xcode after setting environment variables

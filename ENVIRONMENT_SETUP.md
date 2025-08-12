# Environment Setup

This project uses environment variables to securely store API keys. The setup uses user-specific Xcode schemes that are not tracked by git.

## 1. Automatic Setup (Already Done)

I've already set up a user-specific Xcode scheme with your API keys at:
`routine-apps.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes/routine-apps.xcscheme`

This file contains your actual API keys and is automatically ignored by git (due to the `xcuserdata/` directory being in `.gitignore`).

## 2. How It Works

### Shared Scheme (Safe for Git)
The shared scheme at `routine-apps.xcodeproj/xcshareddata/xcschemes/routine-apps.xcscheme` uses placeholder references:
- `$(REPLICATE_API_KEY)` 
- `$(OPENROUTER_API_KEY)`

### User Scheme (Your Local Copy)
Your personal scheme contains the actual API keys and is used by Xcode when you run the app.

## 3. For New Team Members

When someone else clones this repo, they need to:

1. Copy the shared scheme to their user directory:
```bash
mkdir -p routine-apps.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes
cp routine-apps.xcodeproj/xcshareddata/xcschemes/routine-apps.xcscheme routine-apps.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes/routine-apps.xcscheme
```

2. Edit their user-specific scheme with their own API keys:
```bash
# Replace the $(REPLICATE_API_KEY) and $(OPENROUTER_API_KEY) placeholders with actual keys
# in routine-apps.xcodeproj/xcuserdata/$(whoami).xcuserdatad/xcschemes/routine-apps.xcscheme
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

# Deployment Files

This folder contains configuration files for deployment:

## Files

- **render.yaml**: Render.com deployment configuration
- **.gitignore**: Git ignore rules (prevents sensitive files from being uploaded)
- **.env.example**: Template for environment variables (use this as reference)
- **check-deployment-ready.js**: Script to verify deployment readiness

## Testing Deployment Readiness

Run this command to check if your backend is ready:

```bash
node check-deployment-ready.js
```

This will verify:
- ✅ Environment variables are configured
- ✅ Package.json has correct scripts
- ✅ All required files exist
- ✅ .gitignore is properly configured
- ✅ Project structure is correct

## Important Security Notes

⚠️ **NEVER** commit these files to public repositories:
- `.env` (contains sensitive credentials)
- `node_modules/` (too large, rebuilt on server)

✅ **ALWAYS** use environment variables on hosting platforms for:
- Database passwords
- API keys
- Email passwords
- JWT secrets

## Need Help?

See the deployment guides in the project root:
- `DEPLOYMENT_QUICK_START.md` - 5-minute deployment guide
- `DEPLOYMENT_GUIDE.md` - Comprehensive deployment documentation

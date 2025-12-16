# 🚀 Free Deployment Guide for E-Learning System

This guide provides step-by-step instructions to deploy your e-learning project for **FREE** with Gmail email service support.

## 📋 Overview

Your project consists of:
- **Backend**: Node.js/Express API (needs deployment)
- **Frontend**: Flutter app (can be deployed as web or mobile)
- **Database**: MongoDB Atlas (already cloud-hosted ✅)
- **Email**: Gmail with App Password (already configured ✅)

---

## 🎯 Recommended Free Deployment Stack

### Backend Options (Choose ONE):

1. **Render.com** (RECOMMENDED) ⭐
   - 750 hours/month free
   - Auto-deploys from GitHub
   - Environment variables support
   - Never sleeps with proper setup
   - **Best for Gmail SMTP**

2. **Railway.app** (Alternative)
   - $5 free credit/month
   - Easy setup
   - Good for beginners

3. **Fly.io** (Alternative)
   - Free tier available
   - Good performance
   - More technical setup

### Frontend Options:

1. **Flutter Web on Firebase Hosting** (FREE & FAST)
2. **Flutter Web on Netlify** (FREE)
3. **APK Download** (No deployment needed)

---

## 🔧 PART 1: Backend Deployment on Render.com

### Step 1: Prepare Your Backend

1. **Create `.gitignore` in backend folder** (if not exists):

```bash
cd backend
```

Create a file named `.gitignore` with:
```
node_modules/
.env
*.log
.DS_Store
exported_data/
exports/
```

2. **Create `render.yaml` in backend folder**:

```yaml
services:
  - type: web
    name: elearning-backend
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_VERSION
        value: 18.17.0
```

### Step 2: Push to GitHub

```bash
# Initialize git in your project root if not already done
cd C:\Users\QUOC TRIEU\Downloads\flutter4app\Finalproject\elearning_for_it
git init
git add .
git commit -m "Initial commit for deployment"

# Create a new repository on GitHub (https://github.com/new)
# Then push your code:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

### Step 3: Deploy on Render.com

1. **Sign up**: Go to https://render.com and sign up with GitHub
2. **Create Web Service**:
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Configure:
     - **Name**: `elearning-backend` (or your choice)
     - **Root Directory**: `elearningit/backend`
     - **Environment**: `Node`
     - **Build Command**: `npm install`
     - **Start Command**: `npm start`
     - **Instance Type**: `Free`

3. **Add Environment Variables**:
   Click "Environment" tab and add:

   ```
   MONGODB_URI=mongodb+srv://ggcl_elearning:elearning123@cluster0.0uni9.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
   PORT=5000
   JWT_SECRET=elearning_jwt_secret_2024_super_secure_random_key_12345
   FRONTEND_URL=https://your-flutter-app.web.app
   EMAIL_SERVICE=gmail
   EMAIL_USER=trieup920@gmail.com
   EMAIL_PASSWORD=euym yymq sdsj csha
   EMAIL_FROM=E-Learning System <trieup920@gmail.com>
   CLOUDINARY_CLOUD_NAME=du391fsvp
   CLOUDINARY_API_KEY=591468441927346
   CLOUDINARY_API_SECRET=EGZ33NLqLCumwZpcFbgb_wJdiRA
   MAX_FILE_SIZE=10485760
   MAX_VIDEO_SIZE=524288000
   JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
   JUDGE0_API_KEY=db9394fe68msh1ab863034c18fd1p181c82jsn4feb0a731c5b
   JUDGE0_API_HOST=judge0-ce.p.rapidapi.com
   NODE_ENV=production
   ```

4. **Deploy**: Click "Create Web Service"
   - Render will build and deploy your app
   - You'll get a URL like: `https://elearning-backend.onrender.com`

5. **Keep Service Awake** (Important for free tier):
   - Free tier sleeps after 15 minutes of inactivity
   - Use a service like [UptimeRobot](https://uptimerobot.com) (free) to ping your API every 5 minutes

---

## 🌐 PART 2: Frontend Deployment

### Option A: Flutter Web on Firebase Hosting (RECOMMENDED)

1. **Install Firebase CLI**:
```bash
npm install -g firebase-tools
```

2. **Build Flutter Web**:
```bash
cd elearningit
flutter build web --release
```

3. **Initialize Firebase**:
```bash
firebase login
firebase init hosting
```
   - Select your Firebase project (or create new one)
   - Public directory: `build/web`
   - Configure as single-page app: `Yes`
   - Set up automatic builds: `No`

4. **Deploy**:
```bash
firebase deploy --only hosting
```

Your app will be live at: `https://your-project.web.app`

### Option B: Flutter Web on Netlify

1. **Build Flutter Web**:
```bash
cd elearningit
flutter build web --release
```

2. **Create `netlify.toml` in elearningit folder**:
```toml
[build]
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

3. **Deploy**:
   - Go to https://app.netlify.com
   - Drag and drop the `build/web` folder
   - Or connect to GitHub for auto-deploy

### Option C: Android APK (No Deployment)

1. **Build APK**:
```bash
cd elearningit
flutter build apk --release
```

2. **Share the APK**:
   - Find APK at: `build/app/outputs/flutter-apk/app-release.apk`
   - Upload to Google Drive, Dropbox, or your website
   - Users download and install directly

---

## 🔄 PART 3: Update Flutter API Configuration

Once your backend is deployed, update your Flutter app:

### Update `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Use your deployed backend URL
  static const String baseUrl = kIsWeb
      ? 'https://elearning-backend.onrender.com/api'  // Your Render URL
      : Platform.isAndroid
          ? 'https://elearning-backend.onrender.com/api'  // Your Render URL
          : 'https://elearning-backend.onrender.com/api'; // Your Render URL
  
  // Other configurations...
}
```

Then rebuild and redeploy your Flutter app.

---

## 📧 Gmail Configuration (Already Done ✅)

Your Gmail is already configured with App Password. This will work on deployed backend:

**Current Setup**:
- ✅ Email: `trieup920@gmail.com`
- ✅ App Password: `euym yymq sdsj csha`
- ✅ Service: Gmail SMTP

**Important**: Keep your App Password secure and NEVER commit `.env` to public repositories!

---

## 🧪 Testing After Deployment

1. **Test Backend Health**:
```bash
curl https://your-backend-url.onrender.com/api/health
```

2. **Test Email**:
   - Try the forgot password feature
   - Create a test notification

3. **Test Frontend**:
   - Open your deployed URL
   - Test login/signup
   - Test all major features

---

## 🎨 Alternative Free Platforms

### Backend Alternatives:

| Platform | Free Tier | Notes |
|----------|-----------|-------|
| **Render** | 750 hrs/month | ⭐ Recommended, best for Node.js |
| **Railway** | $5 credit/month | Easy setup |
| **Fly.io** | 3 VMs free | Good performance |
| **Heroku** | No longer free | ❌ |
| **Vercel** | Serverless only | Limited for Express apps |

### Frontend Alternatives:

| Platform | Free Tier | Notes |
|----------|-----------|-------|
| **Firebase** | 10GB storage, 360MB/day | ⭐ Recommended for Flutter Web |
| **Netlify** | 100GB bandwidth/month | Great for static sites |
| **Vercel** | 100GB bandwidth/month | Excellent performance |
| **GitHub Pages** | Unlimited | Public repos only |

---

## 🚨 Important Notes

### 1. Free Tier Limitations:
- **Render**: Service sleeps after 15 min inactivity (use UptimeRobot to keep awake)
- **MongoDB Atlas**: 512MB storage limit
- **Cloudinary**: 25 credits/month (already configured)

### 2. Security Best Practices:
- ✅ Never commit `.env` files
- ✅ Use environment variables on hosting platforms
- ✅ Change JWT_SECRET in production
- ✅ Enable CORS only for your frontend domain

### 3. Performance Tips:
- Enable compression in Express
- Use CDN for static assets (Cloudinary already configured)
- Optimize images before upload
- Use MongoDB indexes (check your models)

---

## 📚 Quick Start Checklist

- [ ] Push code to GitHub
- [ ] Deploy backend on Render.com
- [ ] Add all environment variables
- [ ] Set up UptimeRobot to keep backend awake
- [ ] Update Flutter API config with deployed URL
- [ ] Build Flutter web (`flutter build web`)
- [ ] Deploy Flutter on Firebase Hosting
- [ ] Test login/signup
- [ ] Test email functionality
- [ ] Test file uploads
- [ ] Test all major features

---

## 🆘 Troubleshooting

### Backend won't start on Render:
- Check build logs for errors
- Ensure all environment variables are set
- Verify `package.json` has correct start script

### Email not sending:
- Verify Gmail App Password is correct
- Check Render logs for email errors
- Ensure `EMAIL_SERVICE=gmail` is set

### Flutter app can't connect to backend:
- Check CORS settings in backend
- Verify API URL in `api_config.dart`
- Check browser console for errors

### Database connection fails:
- Verify MongoDB Atlas allows connections from anywhere (0.0.0.0/0)
- Check connection string has correct credentials

---

## 📞 Support Resources

- **Render Docs**: https://render.com/docs
- **Firebase Docs**: https://firebase.google.com/docs/hosting
- **Flutter Web**: https://docs.flutter.dev/deployment/web
- **MongoDB Atlas**: https://www.mongodb.com/docs/atlas/

---

## 🎉 After Successful Deployment

Your app will be accessible at:
- **Backend API**: `https://your-app.onrender.com`
- **Frontend Web**: `https://your-app.web.app`
- **Mobile**: Download APK and install

**Congratulations! Your e-learning system is now live! 🚀**

---

*Last Updated: December 16, 2025*

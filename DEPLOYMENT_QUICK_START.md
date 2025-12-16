# 🚀 Quick Start Deployment (5 Minutes)

## Prerequisites
- GitHub account
- Gmail with App Password (you already have this ✅)
- Your MongoDB Atlas is already cloud-hosted ✅

---

## Step 1: Push to GitHub (2 minutes)

```bash
# Navigate to your project root
cd "C:\Users\QUOC TRIEU\Downloads\flutter4app\Finalproject\elearning_for_it"

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Ready for deployment"

# Create a new repository on GitHub.com
# Then connect and push:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

## Step 2: Deploy Backend on Render.com (2 minutes)

1. Go to https://render.com and sign up with GitHub
2. Click **"New +"** → **"Web Service"**
3. Select your repository
4. Configure:
   - **Name**: `elearning-backend`
   - **Root Directory**: `elearningit/backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free`

5. Click **"Advanced"** and add Environment Variables:
   ```
   MONGODB_URI=mongodb+srv://ggcl_elearning:elearning123@cluster0.0uni9.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
   PORT=5000
   JWT_SECRET=elearning_jwt_secret_2024_super_secure_random_key_12345
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

6. Click **"Create Web Service"**
7. Wait 5-10 minutes for deployment
8. Copy your backend URL: `https://elearning-backend-XXXX.onrender.com`

---

## Step 3: Update Flutter App (1 minute)

Edit `elearningit/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Replace with your Render URL
  static const String baseUrl = 'https://YOUR-BACKEND-URL.onrender.com/api';
  
  // Rest of the code stays the same
}
```

---

## Step 4: Deploy Frontend (Choose ONE)

### Option A: Firebase Hosting (Recommended for Web)

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Build Flutter web
cd elearningit
flutter build web --release

# Login to Firebase
firebase login

# Initialize (first time only)
firebase init hosting
# - Select existing project or create new
# - Public directory: build/web
# - Single-page app: Yes
# - Automatic builds: No

# Deploy
firebase deploy --only hosting
```

Your app is live at: `https://YOUR-PROJECT.web.app`

### Option B: Android APK (No hosting needed)

```bash
cd elearningit
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

Share this APK file with users for direct installation.

---

## Step 5: Keep Backend Awake (Optional but Recommended)

Free tier on Render sleeps after 15 minutes. Keep it awake:

1. Go to https://uptimerobot.com (free)
2. Sign up
3. Add New Monitor:
   - **Type**: HTTP(s)
   - **URL**: Your Render URL + `/api/health`
   - **Interval**: 5 minutes

---

## ✅ Testing Checklist

After deployment, test these features:

- [ ] Open your deployed app URL
- [ ] Sign up with a new account (check email arrives)
- [ ] Log in successfully
- [ ] Create a course (if instructor)
- [ ] Upload a file
- [ ] Create an assignment
- [ ] Test forgot password (check email)
- [ ] Check notifications

---

## 📱 Sharing Your App

### For Web Users:
Share your Firebase URL: `https://your-project.web.app`

### For Android Users:
1. Upload APK to Google Drive
2. Share the download link
3. Users must enable "Install from unknown sources" on their phone

### For iOS Users:
Requires Apple Developer Account ($99/year) - not free

---

## 🆘 Common Issues

### Backend URL not working:
- Wait 10 minutes for first deployment
- Check Render logs for errors
- Verify all environment variables are set

### Email not sending:
- Check your Gmail App Password is correct
- Make sure 2FA is enabled on Gmail
- Check Render logs for errors

### Flutter app can't connect:
- Make sure you updated `api_config.dart` with correct URL
- Rebuild the Flutter app after changing URL
- Check browser console for CORS errors

---

## 🎉 You're Done!

Your e-learning system is now deployed and accessible worldwide!

**Backend API**: https://your-backend.onrender.com  
**Frontend**: https://your-project.web.app (or APK file)

---

## 💡 Next Steps (Optional)

- Custom domain for your app (free with Firebase)
- Set up automatic deployments on GitHub push
- Monitor app performance with Firebase Analytics
- Add more features and redeploy

**Need detailed instructions?** See `DEPLOYMENT_GUIDE.md`

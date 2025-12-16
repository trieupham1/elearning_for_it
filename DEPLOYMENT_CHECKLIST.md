# ✅ Deployment Checklist

Print this checklist and mark items as you complete them!

---

## 📋 PRE-DEPLOYMENT (5 minutes)

### Verify Your Setup:
- [ ] Backend check passed: `node backend/check-deployment-ready.js`
- [ ] Flutter app runs locally: `flutter run`
- [ ] Backend runs locally: `npm run dev` in backend folder
- [ ] Gmail App Password is saved somewhere safe
- [ ] MongoDB Atlas connection string is saved

---

## 🔧 BACKEND DEPLOYMENT (25 minutes)

### 1. GitHub Setup:
- [ ] Created GitHub account (or already have one)
- [ ] Created new repository on GitHub.com
- [ ] Repository is PUBLIC or PRIVATE (your choice)

### 2. Push Code:
```bash
cd "C:\Users\QUOC TRIEU\Downloads\flutter4app\Finalproject\elearning_for_it"
git init
git add .
git commit -m "Initial commit for deployment"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

- [ ] Code pushed to GitHub successfully
- [ ] Can see files on GitHub.com
- [ ] `.env` file is NOT visible on GitHub (security check!)

### 3. Render.com Setup:
- [ ] Signed up at https://render.com
- [ ] Connected GitHub account
- [ ] Created new Web Service
- [ ] Selected correct repository

### 4. Configure Render:
- [ ] Set Name: `elearning-backend`
- [ ] Set Root Directory: `elearningit/backend`
- [ ] Set Build Command: `npm install`
- [ ] Set Start Command: `npm start`
- [ ] Selected Free plan

### 5. Environment Variables on Render:
Add each variable (copy from your `.env` file):

- [ ] `MONGODB_URI`
- [ ] `PORT` = 5000
- [ ] `JWT_SECRET`
- [ ] `EMAIL_SERVICE` = gmail
- [ ] `EMAIL_USER`
- [ ] `EMAIL_PASSWORD`
- [ ] `EMAIL_FROM`
- [ ] `CLOUDINARY_CLOUD_NAME`
- [ ] `CLOUDINARY_API_KEY`
- [ ] `CLOUDINARY_API_SECRET`
- [ ] `MAX_FILE_SIZE`
- [ ] `MAX_VIDEO_SIZE`
- [ ] `JUDGE0_API_URL`
- [ ] `JUDGE0_API_KEY`
- [ ] `JUDGE0_API_HOST`
- [ ] `NODE_ENV` = production
- [ ] `FRONTEND_URL` = (add after frontend is deployed)

### 6. Deploy:
- [ ] Clicked "Create Web Service"
- [ ] Waited for deployment (5-10 minutes)
- [ ] Backend URL received: `https://__________________.onrender.com`
- [ ] Tested health check: `https://your-url/api/health`

---

## 🌐 FRONTEND DEPLOYMENT (15 minutes)

### Option A: Firebase Hosting (Web App)

#### 1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```
- [ ] Firebase CLI installed

#### 2. Update API Config:
Edit `elearningit/lib/config/api_config.dart`:
- [ ] Changed `baseUrl` to your Render URL
- [ ] Saved file

#### 3. Build Flutter Web:
```bash
cd elearningit
flutter build web --release
```
- [ ] Build completed successfully
- [ ] `build/web` folder exists

#### 4. Firebase Setup:
```bash
firebase login
firebase init hosting
```
- [ ] Logged into Firebase
- [ ] Selected/created Firebase project
- [ ] Set public directory: `build/web`
- [ ] Configured as single-page app: YES

#### 5. Deploy:
```bash
firebase deploy --only hosting
```
- [ ] Deployment successful
- [ ] Frontend URL received: `https://__________________.web.app`
- [ ] Can access app in browser

#### 6. Update Backend FRONTEND_URL:
- [ ] Go to Render.com dashboard
- [ ] Update `FRONTEND_URL` environment variable
- [ ] Trigger redeploy if needed

---

### Option B: Android APK

#### 1. Update API Config:
- [ ] Changed `baseUrl` to your Render URL in `api_config.dart`
- [ ] Saved file

#### 2. Build APK:
```bash
cd elearningit
flutter build apk --release
```
- [ ] Build completed successfully
- [ ] APK found at: `build/app/outputs/flutter-apk/app-release.apk`

#### 3. Share APK:
- [ ] Uploaded APK to Google Drive/Dropbox
- [ ] Shared link created
- [ ] Tested installation on Android device

---

## 🎯 UPTIME MONITORING (5 minutes)

### Keep Backend Awake:
- [ ] Signed up at https://uptimerobot.com
- [ ] Created new HTTP(s) monitor
- [ ] URL: `https://your-backend-url.onrender.com/api/health`
- [ ] Interval: 5 minutes
- [ ] Monitor is active

---

## 🧪 TESTING (10 minutes)

### Backend Tests:
- [ ] Health endpoint works: `/api/health`
- [ ] Can view API in browser
- [ ] No errors in Render logs

### Frontend Tests:
- [ ] App loads in browser (for web) or phone (for APK)
- [ ] Can see login screen
- [ ] Design looks correct

### Authentication Tests:
- [ ] Can register new account
- [ ] Received welcome email
- [ ] Can login with credentials
- [ ] JWT token is working

### Email Tests:
- [ ] Registration email received
- [ ] Try "Forgot Password"
- [ ] Reset password email received
- [ ] Email link works

### Core Features:
- [ ] Can view dashboard
- [ ] Can create course (instructor)
- [ ] Can upload file
- [ ] Can create assignment
- [ ] Notifications work
- [ ] All tabs accessible

---

## 📱 SHARING YOUR APP

### For Web App:
- [ ] Share URL: `https://your-project.web.app`
- [ ] Tested on different browsers
- [ ] Tested on mobile browser
- [ ] Created bookmark/shortcut

### For Android APK:
- [ ] Share download link
- [ ] Provided installation instructions
- [ ] Tested on multiple devices
- [ ] Users can install successfully

---

## 📊 POST-DEPLOYMENT

### Documentation:
- [ ] Saved backend URL
- [ ] Saved frontend URL
- [ ] Saved all credentials securely
- [ ] Created user guide (optional)

### Monitoring:
- [ ] UptimeRobot is monitoring
- [ ] Check Render dashboard for usage
- [ ] Check MongoDB Atlas for storage
- [ ] Check Cloudinary for credits

### Backup:
- [ ] Code is on GitHub ✅
- [ ] Database is on MongoDB Atlas ✅
- [ ] Environment variables documented ✅

---

## 🎉 SUCCESS CRITERIA

You've successfully deployed when:

- ✅ Backend is accessible via HTTPS URL
- ✅ Frontend loads and looks correct
- ✅ Users can register and receive email
- ✅ Users can login and use features
- ✅ No console errors in browser
- ✅ Emails are being sent
- ✅ File uploads work
- ✅ All major features function correctly

---

## 📝 DEPLOYMENT INFO (Fill This In)

### URLs:
- **Backend API**: https://________________________________.onrender.com
- **Frontend Web**: https://________________________________.web.app
- **GitHub Repo**: https://github.com/_____________________________

### Credentials Storage:
- [ ] Saved all passwords in password manager
- [ ] Documented environment variables
- [ ] Saved GitHub login info
- [ ] Saved Render.com login info
- [ ] Saved Firebase login info

### Dates:
- **Deployed**: ____________
- **Last Updated**: ____________
- **Next Review**: ____________

---

## 🆘 IF SOMETHING GOES WRONG

### Backend Issues:
1. Check Render logs for errors
2. Verify all environment variables are set
3. Check MongoDB Atlas allows all IPs (0.0.0.0/0)
4. Verify `server.js` starts without errors locally

### Email Issues:
1. Check Gmail App Password is correct
2. Verify 2FA is enabled on Gmail
3. Check Render environment variables
4. Look for email errors in Render logs

### Frontend Issues:
1. Check browser console for errors
2. Verify API URL is correct in `api_config.dart`
3. Rebuild and redeploy after changes
4. Test in incognito mode

### Database Issues:
1. Check MongoDB Atlas connection string
2. Verify network access settings (allow all IPs)
3. Check database user permissions
4. Test connection locally first

---

## 📞 HELP RESOURCES

- **Render Docs**: https://render.com/docs
- **Firebase Docs**: https://firebase.google.com/docs
- **Flutter Deployment**: https://docs.flutter.dev/deployment
- **MongoDB Atlas**: https://www.mongodb.com/docs/atlas
- **Project Guides**: See `DEPLOYMENT_GUIDE.md`

---

## ✨ CONGRATULATIONS!

Once all checkboxes are marked, your e-learning platform is:
- 🌐 Accessible worldwide
- 📧 Sending emails
- 💾 Storing data in the cloud
- 🔒 Secure and production-ready
- 💰 Running completely FREE

**You did it! 🎊**

---

*Keep this checklist for future deployments and updates!*

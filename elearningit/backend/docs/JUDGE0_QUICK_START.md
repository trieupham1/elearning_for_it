# Quick Start: Judge0 API Setup

## Step 1: Get Your Judge0 API Key (5 minutes)

### Option A: RapidAPI (Recommended for Development)

1. **Go to RapidAPI Judge0 Page**
   - Visit: https://rapidapi.com/judge0-official/api/judge0-ce
   - Click "Sign Up" or "Log In" (top right)

2. **Create Account** (if new user)
   - Sign up with Google, GitHub, or email
   - Verify your email

3. **Subscribe to Judge0 CE**
   - On the Judge0 CE page, click "Subscribe to Test"
   - Choose a plan:
     - **FREE**: 50 requests/day (good for testing)
     - **Basic**: $10/month - 10,000 requests
     - **Pro**: $50/month - 100,000 requests
   - For testing, select **FREE** plan
   - Click "Subscribe"

4. **Copy Your API Key**
   - After subscribing, you'll see your API key at the top
   - It looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
   - Click the "Copy" button

5. **Test Your API Key**
   - Go to "Code Snippets" tab
   - Click "Test Endpoint"
   - Should see successful response

## Step 2: Add API Key to Backend

1. **Open your `.env` file**
   ```bash
   cd elearningit/backend
   notepad .env
   ```

2. **Add these lines** (replace with your actual key):
   ```env
   # Judge0 Configuration for Code Assignments
   JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
   JUDGE0_API_KEY=your_actual_api_key_here
   JUDGE0_API_HOST=judge0-ce.p.rapidapi.com
   ```

3. **Save the file** (Ctrl+S)

## Step 3: Restart Backend Server

```bash
# Stop current server (Ctrl+C if running)
# Then restart:
npm run dev
```

**Expected Output:**
```
Connected to MongoDB
GridFS initialized
✓ Judge0 API configured
Server running on port 5000
```

If you see `✗ Judge0 API not configured`, check that:
- API key is copied correctly (no extra spaces)
- .env file is in `backend/` folder
- Server was restarted after adding key

## Step 4: Test Code Execution

### Using Postman or Thunder Client:

**1. Create a Code Assignment:**
```http
POST http://localhost:5000/api/code/assignments
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "courseId": "your_course_id",
  "title": "Test Assignment",
  "description": "Print Hello World",
  "language": "python",
  "starterCode": "# Write your code here\n",
  "deadline": "2025-12-31T23:59:59Z",
  "points": 100,
  "testCases": [
    {
      "name": "Test 1",
      "input": "",
      "expectedOutput": "Hello, World!",
      "weight": 1
    }
  ]
}
```

**2. Submit Code:**
```http
POST http://localhost:5000/api/code/assignments/{assignment_id}/submit
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "code": "print('Hello, World!')",
  "language": "python"
}
```

**3. Check Results:**
```http
GET http://localhost:5000/api/code/submissions/{submission_id}
Authorization: Bearer YOUR_JWT_TOKEN
```

You should see:
```json
{
  "status": "completed",
  "totalScore": 100,
  "passedTests": 1,
  "totalTests": 1
}
```

## Troubleshooting

### Error: "Code execution failed"
- **Cause**: Invalid API key
- **Solution**: Check RapidAPI dashboard, copy key again

### Error: "Request limit exceeded"
- **Cause**: Free plan limit (50/day) reached
- **Solution**: Wait 24 hours or upgrade plan

### Error: "Judge0 API not configured"
- **Cause**: JUDGE0_API_KEY not in .env
- **Solution**: Add to .env and restart server

### Server starts but no "✓ Judge0 API configured"
- **Cause**: .env file not loaded
- **Solution**: Check dotenv is installed: `npm install dotenv`

## Rate Limits

**Free Plan**: 50 requests/day
- = ~5 students × 10 submissions each
- Good for: Testing, small demos

**Basic Plan** ($10/month): 10,000 requests/month
- = ~100 students × 100 submissions each
- Good for: Small courses (1-2 classes)

**Pro Plan** ($50/month): 100,000 requests/month
- = ~1000 students × 100 submissions each
- Good for: Large courses, production use

**Pro Tip**: For production with >1000 students, consider self-hosting Judge0 (unlimited, free)

## Next Steps

✅ API key configured  
✅ Backend server running  
✅ Code execution tested  

Now you can:
1. Create code assignments from frontend
2. Students can submit code
3. Auto-grading works instantly

## Support Links

- **RapidAPI Dashboard**: https://rapidapi.com/developer/dashboard
- **Judge0 Documentation**: https://ce.judge0.com/
- **Support**: https://github.com/judge0/judge0/discussions

---

**Setup Time**: ~5 minutes  
**Cost**: Free for testing  
**Status**: Ready to use! 🚀

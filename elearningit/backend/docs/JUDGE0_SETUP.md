# Judge0 API Setup for Code Assignments

## Overview
The E-Learning platform uses Judge0 CE (Community Edition) for executing student code submissions safely in a sandboxed environment. Judge0 supports multiple programming languages and provides resource limits for security.

## Supported Languages
- **Python 3** (Judge0 ID: 71)
- **Java** (Judge0 ID: 62)
- **C++** (Judge0 ID: 54)
- **JavaScript (Node.js)** (Judge0 ID: 63)
- **C** (Judge0 ID: 50)

## Setup Options

### Option 1: RapidAPI (Recommended for Development)
The easiest way to get started with Judge0 for development and testing.

**Steps:**
1. Go to [Judge0 CE on RapidAPI](https://rapidapi.com/judge0-official/api/judge0-ce)
2. Click "Subscribe to Test"
3. Choose a pricing plan:
   - **Free Tier**: 50 requests/day (good for testing)
   - **Basic**: $10/month - 10,000 requests/month
   - **Pro**: $50/month - 100,000 requests/month
4. Copy your API key from the RapidAPI dashboard
5. Add to your `.env` file:
   ```env
   JUDGE0_API_KEY=your_rapidapi_key_here
   JUDGE0_API_HOST=judge0-ce.p.rapidapi.com
   JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
   ```

### Option 2: Self-Hosted (Production)
For production environments, self-hosting Judge0 gives you unlimited requests and full control.

**Requirements:**
- Docker and Docker Compose installed
- At least 2GB RAM
- Linux server recommended

**Steps:**
1. Clone the Judge0 repository:
   ```bash
   git clone https://github.com/judge0/judge0.git
   cd judge0
   ```

2. Copy the example configuration:
   ```bash
   cp docker-compose.yml.example docker-compose.yml
   ```

3. Start Judge0 services:
   ```bash
   docker-compose up -d
   ```

4. Judge0 will be running at `http://localhost:2358`

5. Update your `.env` file:
   ```env
   JUDGE0_API_URL=http://localhost:2358
   JUDGE0_API_KEY=  # Leave empty for self-hosted
   JUDGE0_API_HOST=  # Leave empty for self-hosted
   ```

### Option 3: Judge0 Extra CE (More Languages)
If you need additional languages like Ruby, PHP, Go, etc.

1. Go to [Judge0 Extra CE on RapidAPI](https://rapidapi.com/judge0-official/api/judge0-extra-ce)
2. Follow the same subscription process
3. Update configuration in `.env`

## Configuration File (.env)

Add these environment variables to your `backend/.env`:

```env
# Judge0 Configuration
JUDGE0_API_URL=https://judge0-ce.p.rapidapi.com
JUDGE0_API_KEY=your_rapidapi_key_here
JUDGE0_API_HOST=judge0-ce.p.rapidapi.com
```

## Testing the Integration

### 1. Start the Backend Server
```bash
cd backend
npm install
npm run dev
```

You should see:
```
✓ Judge0 API configured
```

If not configured:
```
✗ Judge0 API not configured - code assignments will not work
⚠️  WARNING: JUDGE0_API_KEY not set in environment variables
```

### 2. Test with Sample Code

**Create a Code Assignment:**
```bash
POST /api/code/assignments
{
  "courseId": "...",
  "title": "Hello World in Python",
  "language": "python",
  "starterCode": "# Write your code here\n",
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

**Submit Code:**
```bash
POST /api/code/assignments/:id/submit
{
  "code": "print('Hello, World!')",
  "language": "python"
}
```

**Expected Response:**
```json
{
  "message": "Code submitted successfully",
  "submissionId": "...",
  "status": "running"
}
```

**Check Results:**
```bash
GET /api/code/submissions/:submissionId
```

**Expected Response:**
```json
{
  "status": "completed",
  "totalScore": 100,
  "passedTests": 1,
  "totalTests": 1,
  "testResults": [
    {
      "status": "passed",
      "executionTime": 45.2,
      "memoryUsed": 3840
    }
  ]
}
```

## API Endpoints

### For Instructors
- `POST /api/code/assignments` - Create code assignment with test cases
- `GET /api/code/assignments/:id` - Get assignment details (includes hidden tests)
- `GET /api/code/assignments/:id/submissions` - View all student submissions
- `POST /api/code/assignments/:id/test-cases` - Add test case
- `DELETE /api/code/test-cases/:id` - Remove test case
- `GET /api/code/assignments/:id/leaderboard` - View top performers

### For Students
- `GET /api/code/assignments/:id` - Get assignment details (visible tests only)
- `POST /api/code/assignments/:id/submit` - Submit code solution
- `POST /api/code/assignments/:id/test` - Test code without submitting (dry run)
- `GET /api/code/submissions/:id` - Get submission result
- `GET /api/code/assignments/:id/my-submissions` - View submission history

## Resource Limits

Default limits can be configured per assignment:

- **Time Limit**: 5 seconds (5000ms)
- **Memory Limit**: 128 MB (128000 KB)
- **Max Attempts**: Unlimited (999)

These can be customized in the assignment creation request:
```json
{
  "timeLimit": 10000,
  "memoryLimit": 256000
}
```

## Security Features

✓ **Sandboxed Execution**: All code runs in isolated Docker containers  
✓ **Resource Limits**: CPU time and memory limits prevent infinite loops  
✓ **Network Isolation**: No internet access from student code  
✓ **Hidden Test Cases**: Students can't see all test cases  
✓ **Solution Protection**: Instructor solutions are never exposed to students  

## Troubleshooting

### Error: "Code execution failed"
- Check that JUDGE0_API_KEY is set correctly
- Verify RapidAPI subscription is active
- Check network connectivity to Judge0 API

### Error: "Time limit exceeded"
- Increase timeLimit in assignment configuration
- Check for infinite loops in code
- Optimize algorithm complexity

### Error: "Memory limit exceeded"
- Increase memoryLimit in assignment configuration
- Check for memory leaks (large arrays, recursion depth)

### Error: "Compilation error"
- Syntax error in student code
- Check error details in `testResults[].errorMessage`

## Cost Estimation

### RapidAPI Pricing (as of 2024)
- **Free**: 50 requests/day = ~1,500/month (testing only)
- **Basic ($10/month)**: 10,000 requests = ~333 students × 30 submissions each
- **Pro ($50/month)**: 100,000 requests = ~3,333 students × 30 submissions each

### Self-Hosted
- **Cost**: Server hosting only (~$10-20/month for VPS)
- **Requests**: Unlimited
- **Recommended for**: >1000 students or production use

## Language-Specific Notes

### Python
- Version: Python 3.8.1
- Common imports available: math, sys, itertools, collections, etc.

### Java
- Version: OpenJDK 13.0.1
- Main class must be named `Main`
- Example:
  ```java
  public class Main {
      public static void main(String[] args) {
          System.out.println("Hello");
      }
  }
  ```

### C++
- Version: GCC 9.2.0
- Standard: C++17
- Example:
  ```cpp
  #include <iostream>
  using namespace std;
  int main() {
      cout << "Hello" << endl;
      return 0;
  }
  ```

### JavaScript
- Version: Node.js 12.14.0
- Use console.log() for output

### C
- Version: GCC 9.2.0
- Standard: C11

## Next Steps

1. **Get API Key**: Sign up at RapidAPI (5 minutes)
2. **Configure .env**: Add Judge0 credentials
3. **Restart Server**: npm run dev
4. **Create Test Assignment**: Use Postman or frontend
5. **Submit Sample Code**: Verify execution works
6. **Build Frontend**: Implement code editor UI

## Additional Resources

- [Judge0 Documentation](https://ce.judge0.com/)
- [Judge0 GitHub](https://github.com/judge0/judge0)
- [RapidAPI Judge0 CE](https://rapidapi.com/judge0-official/api/judge0-ce)
- [Supported Languages List](https://ce.judge0.com/#statuses-and-languages-language)

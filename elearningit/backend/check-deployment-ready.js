// Pre-deployment checklist script
const fs = require('fs');
const path = require('path');

console.log('🔍 E-Learning Deployment Readiness Check\n');
console.log('='.repeat(50));

let allGood = true;

// Check 1: Environment variables
console.log('\n1. Checking .env file...');
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  console.log('   ✅ .env file exists');
  const envContent = fs.readFileSync(envPath, 'utf8');
  
  const requiredVars = [
    'MONGODB_URI',
    'PORT',
    'JWT_SECRET',
    'EMAIL_SERVICE',
    'EMAIL_USER',
    'EMAIL_PASSWORD',
    'CLOUDINARY_CLOUD_NAME'
  ];
  
  requiredVars.forEach(varName => {
    if (envContent.includes(varName)) {
      console.log(`   ✅ ${varName} is set`);
    } else {
      console.log(`   ❌ ${varName} is missing`);
      allGood = false;
    }
  });
} else {
  console.log('   ❌ .env file not found');
  allGood = false;
}

// Check 2: Package.json
console.log('\n2. Checking package.json...');
const packagePath = path.join(__dirname, 'package.json');
if (fs.existsSync(packagePath)) {
  console.log('   ✅ package.json exists');
  const pkg = require(packagePath);
  
  if (pkg.scripts && pkg.scripts.start) {
    console.log('   ✅ "start" script is defined:', pkg.scripts.start);
  } else {
    console.log('   ❌ "start" script is missing');
    allGood = false;
  }
  
  if (pkg.dependencies) {
    console.log('   ✅ Dependencies are defined');
  } else {
    console.log('   ❌ No dependencies found');
    allGood = false;
  }
} else {
  console.log('   ❌ package.json not found');
  allGood = false;
}

// Check 3: Main server file
console.log('\n3. Checking server.js...');
const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
  console.log('   ✅ server.js exists');
} else {
  console.log('   ❌ server.js not found');
  allGood = false;
}

// Check 4: .gitignore
console.log('\n4. Checking .gitignore...');
const gitignorePath = path.join(__dirname, '.gitignore');
if (fs.existsSync(gitignorePath)) {
  console.log('   ✅ .gitignore exists');
  const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
  if (gitignoreContent.includes('.env')) {
    console.log('   ✅ .env is ignored (security ✓)');
  } else {
    console.log('   ⚠️  .env should be in .gitignore');
  }
  if (gitignoreContent.includes('node_modules')) {
    console.log('   ✅ node_modules is ignored');
  } else {
    console.log('   ⚠️  node_modules should be in .gitignore');
  }
} else {
  console.log('   ⚠️  .gitignore not found (recommended)');
}

// Check 5: Required folders
console.log('\n5. Checking project structure...');
const requiredFolders = ['routes', 'models', 'middleware', 'utils'];
requiredFolders.forEach(folder => {
  const folderPath = path.join(__dirname, folder);
  if (fs.existsSync(folderPath)) {
    console.log(`   ✅ ${folder}/ exists`);
  } else {
    console.log(`   ❌ ${folder}/ not found`);
    allGood = false;
  }
});

// Check 6: Node version
console.log('\n6. Checking Node.js version...');
const nodeVersion = process.version;
console.log(`   ℹ️  Current version: ${nodeVersion}`);
const major = parseInt(nodeVersion.split('.')[0].substring(1));
if (major >= 16) {
  console.log('   ✅ Node.js version is compatible');
} else {
  console.log('   ⚠️  Node.js 16+ is recommended');
}

// Final verdict
console.log('\n' + '='.repeat(50));
if (allGood) {
  console.log('\n✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅');
  console.log('\n🚀 Your backend is ready for deployment!');
  console.log('\nNext steps:');
  console.log('1. Push your code to GitHub');
  console.log('2. Deploy on Render.com');
  console.log('3. Add environment variables on Render');
  console.log('\nSee DEPLOYMENT_QUICK_START.md for detailed instructions');
} else {
  console.log('\n❌ Some issues need to be fixed before deployment');
  console.log('\nPlease fix the issues marked with ❌ above');
}
console.log('\n' + '='.repeat(50) + '\n');

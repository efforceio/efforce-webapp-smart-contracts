const {execSync} = require('child_process')
const fs = require('fs');
const dotenv = require('dotenv');

const envPath = '.env';
const envConfig = dotenv.parse(fs.readFileSync(envPath));

const env = process.argv[3];
const addScript = env === 'testnet' ? '-testnet' : '';
const addEnv = env === 'testnet' ? '_MUMBAI' : '';

if (!envConfig[`UTILS${addEnv}`]) {
    execSync(`npm run deploy-utils${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`ROLES${addEnv}`]) {
    execSync(`npm run deploy-roles${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`BANK${addEnv}`]) {
    execSync(`npm run deploy-bank${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`POOLS${addEnv}`]) {
    execSync(`npm run deploy-pools${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`CREDITS${addEnv}`]) {
    execSync(`npm run deploy-credits${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`STORE${addEnv}`]) {
    execSync(`npm run deploy-store${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`SWAP${addEnv}`]) {
    execSync(`npm run deploy-swap${addScript}`, {stdio: 'inherit'});
}

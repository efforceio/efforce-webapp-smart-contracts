const {execSync} = require('child_process')
const fs = require('fs');
const dotenv = require('dotenv');

const envPath = '.env';
const envConfig = dotenv.parse(fs.readFileSync(envPath));

const env = process.argv[3];
const addScript = env === 'testnet' ? 'polygon_mumbai' : '';
const addEnv = env === 'testnet' ? '_MUMBAI' : '';

if (!envConfig[`UTILS${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-utils.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`ROLES${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-roles.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`BANK${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-bank.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`POOLS${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-pools.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`CREDITS${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-credits.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`STORE${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-store.ts --network ${addScript}`, {stdio: 'inherit'});
}
if (!envConfig[`SWAP${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-swap.ts --network ${addScript}`, {stdio: 'inherit'});
}

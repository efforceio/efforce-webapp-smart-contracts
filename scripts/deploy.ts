const {execSync} = require('child_process')
const fs = require('fs');
const dotenv = require('dotenv');

const envPath = '.env';
const envConfig = dotenv.parse(fs.readFileSync(envPath));

const addScript = process.argv[3];
let addEnv = `_${addScript.toUpperCase()}`;

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
if (!envConfig[`LOCKING${addEnv}`]) {
    execSync(`hardhat run scripts/deploy-locking.ts --network ${addScript}`, {stdio: 'inherit'});
}

# Efforce marketplace blockchain

This is the repository of the web3 backend for the Efforce project. The repository is divided into six smart contracts:

- Bank
- Credits
- Pools
- Roles
- Store
- Swap

To install necessary packages, run `npm install`.

```mermaid
    graph TD;
        Roles --> Bank;
        Roles --> Credits;
        Bank --> Credits;
        Roles --> Pools;
        Bank --> Pools;
        Credits --> Store;
        Bank --> Store;
        Roles --> Store;
        Credits --> Swap;
        Bank --> Swap;
```

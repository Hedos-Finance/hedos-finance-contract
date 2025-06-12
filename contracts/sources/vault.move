// module delta_hedging::vault {
//     use std::signer;
//     use std::error;
//     use aptos_framework::coin;

//     const EINSUFFICIENT_BALANCE: u64 = 1;
//     const EVAULT_NOT_INITIALIZED: u64 = 2;
//     const EVAULT_ALREADY_INITIALIZED: u64 = 3;

//     struct Vault has key {
//         balance: coin::Coin<USDC>,
//     }

//     struct USDC has drop, store {}

//     public entry fun initialize_vault(account: &signer) {
//         let signer_address = signer::address_of(account);
//         assert!(!exists<Vault>(signer_address), error::already_exists(EVAULT_ALREADY_INITIALIZED));
        
      
//         let vault = Vault {
//             balance: coin::zero<USDC>()
//         };
//         move_to(account, vault);
//     }

  
//     public entry fun deposit(account: &signer, amount: u64) acquires Vault {
//         let signer_address = signer::address_of(account);
//         assert!(exists<Vault>(signer_address), error::not_found(EVAULT_NOT_INITIALIZED));
        
//         let coins = coin::withdraw<USDC>(account, amount);
//         let vault = borrow_global_mut<Vault>(signer_address);
//         coin::merge(&mut vault.balance, coins);
//     }


//     public entry fun withdraw(account: &signer, amount: u64) acquires Vault {
//         let signer_address = signer::address_of(account);
//         assert!(exists<Vault>(signer_address), error::not_found(EVAULT_NOT_INITIALIZED));
        
//         let vault = borrow_global_mut<Vault>(signer_address);
//         assert!(coin::value(&vault.balance) >= amount, error::invalid_argument(EINSUFFICIENT_BALANCE));
        
//         let coins = coin::extract(&mut vault.balance, amount);
//         coin::deposit(signer_address, coins);
//     }

//     public fun get_balance(account_addr: address): u64 acquires Vault {
//         assert!(exists<Vault>(account_addr), error::not_found(EVAULT_NOT_INITIALIZED));
//         let vault = borrow_global<Vault>(account_addr);
//         coin::value(&vault.balance)
//     }
// }
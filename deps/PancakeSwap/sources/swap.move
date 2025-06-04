module pancake::swap {
    // use std::string;
    // use aptos_std::type_info;
    // use aptos_std::event;

    // use aptos_framework::coin;
    // use aptos_framework::timestamp;
    // use aptos_framework::account;
    // use aptos_framework::resource_account;
    // use aptos_framework::code;

    // struct SwapInfo has key {
    //     signer_cap: account::SignerCapability,
    //     fee_to: address,
    //     admin: address,
    //     pair_created: event::EventHandle<PairCreatedEvent>
    // }
    
    // struct PairCreatedEvent has drop, store {
    //     user: address,
    //     token_x: string::String,
    //     token_y: string::String
    // }

    public entry fun set_admin(sender: &signer, new_admin: address) {
        abort 0;
    }
}
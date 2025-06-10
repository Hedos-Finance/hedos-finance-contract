module amnis::router {
    public entry fun deposit_and_stake_entry(
        depositor: &signer, 
        amount: u64, 
        receiver: address) {
        abort 0;
    }

    public entry fun unstake_entry(
        unstaker: &signer, 
        amount: u64, 
        receiver: address) {
        abort 0;
    }

    public entry fun request_withdrawal_entry(
        requester: &signer,
        amount: u64,
        receiver: address
    ) {
        abort 0;
    }

    public entry fun withdraw_entry(
        withdrawer: &signer,
        amount: u64,
        receiver: address
    ) {
        abort 0;
    }

}
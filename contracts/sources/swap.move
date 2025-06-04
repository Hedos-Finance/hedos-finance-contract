module delta_hedging::swap {
    use pancakeswap::router;
    
    public entry fun swap<X, Y>(
        sender: &signer,
        x_in: u64,
        y_min_out: u64
    ) {
        router::swap_exact_input<X, Y>(
            sender,
            x_in,
            y_min_out
        );
    }
}

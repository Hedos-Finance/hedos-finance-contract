module delta_hedging::interact_pancake {
    use pancake::swap;

    public entry fun set_admin(sender: &signer, new_admin: address) {
        swap::set_admin(sender, new_admin);
    }
}   
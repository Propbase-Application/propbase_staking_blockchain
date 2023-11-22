
module propbase::prop_coin {
    use aptos_framework::coin;
    struct PROP {}

    fun init_module(sender: &signer) {
        aptos_framework::managed_coin::initialize<PROP>(
            sender,
            b"Test Coin",
            b"TEST",
            8,
            false,
        );
    }

    #[test_only]
    public entry fun init_test(sender: &signer){
        aptos_framework::managed_coin::initialize<PROP>(
            sender,
            b"Test Coin",
            b"TEST",
            8,
            false,
        );
    }
    public entry fun register(account: &signer) {
        aptos_framework::managed_coin::register<PROP>(account)
    }

    public entry fun mint(account: &signer, dst_addr: address, amount: u64) {
        aptos_framework::managed_coin::mint<PROP>(account, dst_addr, amount);
    }

    public entry fun burn(account: &signer, amount: u64) {
        aptos_framework::managed_coin::burn<PROP>(account, amount);
    }

    public entry fun transfer(from: &signer, to: address, amount: u64,) {
        coin::transfer<PROP>(from, to, amount);
    }
}
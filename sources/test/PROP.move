#[test_only]
module propbase::propbase_coin {
    use aptos_framework::coin;
    struct PROPS {}

    fun init_module(sender: &signer) {
        aptos_framework::managed_coin::initialize<PROPS>(
            sender,
            b"Propbase",
            b"PROPS",
            8,
            false,
        );
    }

    #[test_only]
    public entry fun init_test(sender: &signer){
        aptos_framework::managed_coin::initialize<PROPS>(
            sender,
            b"Propbase",
            b"PROPS",
            8,
            false,
        );
    }
    public entry fun register(account: &signer) {
        aptos_framework::managed_coin::register<PROPS>(account)
    }

    public entry fun mint(account: &signer, dst_addr: address, amount: u64) {
        aptos_framework::managed_coin::mint<PROPS>(account, dst_addr, amount);
    }

    public entry fun burn(account: &signer, amount: u64) {
        aptos_framework::managed_coin::burn<PROPS>(account, amount);
    }

    public entry fun transfer(from: &signer, to: address, amount: u64,) {
        coin::transfer<PROPS>(from, to, amount);
    }
}
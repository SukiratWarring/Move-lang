module myAddress::Warin_coin2{
    use std::signer;
    use std::string;
    use std::account;
    use aptos_framework::coin::{Self,zero,Coin,DepositEvent,WithdrawEvent};
    use aptos_framework::event::{Self, EventHandle};

    const ENOT_OWNER: u64 = 0;
    const E_ALREADY_HAS_CAPABILITY: u64 = 1;
    const E_DONT_HAVE_CAPABILITY: u64 = 2;

    struct Warin  {}

    struct WarinCapability has key{
        burn_cap: coin::BurnCapability<Warin>,
        freeze_cap: coin::FreezeCapability<Warin>,
        mint_cap: coin::MintCapability<Warin>,
    }        

    fun only_owner(addr:address){
        assert!(addr == @myAddress, ENOT_OWNER); 
    }


    public entry fun initialize_and_create_coinstore(account: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Warin>(
            account,
            string::utf8(b"WARIN"),
            string::utf8(b"WAR"),
            18,
            true,
        );

        move_to(account,WarinCapability {
            burn_cap:burn_cap,
            freeze_cap:freeze_cap,
            mint_cap:mint_cap,
        });

    }

}
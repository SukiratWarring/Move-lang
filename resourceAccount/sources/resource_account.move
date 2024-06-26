module myAddress::Resource_account{
    use std::signer;
    use std::string;

    use aptos_framework::coin::{Self};
    use aptos_framework::resource_account;

    struct StakeCoin has key{}

    struct StakeCoinCapability has key{
    burn_cap: coin::BurnCapability<StakeCoin>,
    freeze_cap: coin::FreezeCapability<StakeCoin>,
    mint_cap: coin::MintCapability<StakeCoin>,
    }    

    public entry fun init_coin(account:&signer){
        let addr=signer::address_of(account);
        let(burn_cap,freeze_cap,mint_cap)=coin::initialize<StakeCoin>(
            account,
            string::utf8(b"Stake_Coin"),
            string::utf8(b"STC"),
            8,
            true,
        );
        move_to(account,StakeCoinCapability{
            burn_cap,
            freeze_cap,
            mint_cap,
        });
        coin::register(account)

    }

    // public fun create_resource_accounts(){

    // }
}
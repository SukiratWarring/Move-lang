#[test_only]
module myAddress::Test_Lockcontract{
    use std::signer;
    use std::vector;
    use std::string;
    use myAddress::LockContract;
    use myAddress::LockContract::LockDetails;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::debug::print;
    use std::timestamp;

    fun setup_enviroment(test_acc:&signer){
        timestamp::set_time_has_started_for_testing(test_acc);
        account::create_account_for_test(signer::address_of(test_acc));
        LockContract::init<AptosCoin>(test_acc);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            test_acc,
            string::utf8(b"TestCoin"),
            string::utf8(b"TC"),
            8,
            false,
        );
        coin::register<AptosCoin>(test_acc);
        let coins =coin::mint<AptosCoin>(20000,&mint_cap);
        coin::deposit(signer::address_of(test_acc), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);        
        coin::destroy_burn_cap(burn_cap);        
    }
    
    #[test(test_acc=@aptos_framework)]
    public entry fun create_lock(test_acc:&signer){
        setup_enviroment(test_acc);
        LockContract::lock<AptosCoin>(test_acc,20000,20000);
        timestamp::fast_forward_seconds(30000);
        //check the lock
        let check_all_locks=LockContract::getAllLocks<AptosCoin>(test_acc);
        assert!(vector::length(&check_all_locks)==1,0);
        let total_rewards=LockContract::calcualte_rewards<AptosCoin>(test_acc);
        print(&total_rewards);
    }
}
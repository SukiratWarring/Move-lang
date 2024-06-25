#[test_only]
module myAddress::token_test{
    use std::signer;
    use std::unit_test;
    use std::vector;
    use std::debug::print;
    //ERROR CODES
    const BALANCE_ALREADY_EXISTS:u64=1;
    const BALANCE_DOESNOT_EXISTS:u64=2;
    const BALANCE_IS_LESS:u64=3;
    const SENDING_AND_RECEIVEING_ARE_SAME:u64=4;

    use myAddress::Token;
    fun get_account():signer{
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    public fun setup_test_environment(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        Token::create_balance(account);
    }

    #[test]
    public fun test_create_balance(){
        let account=get_account();
        setup_test_environment(&account);
        let addr = signer::address_of(&account);
        assert!(Token::check_balance(addr),12);
        
    }

    #[test(account=@myAddress)]
    public fun test_mint(account:signer){
        setup_test_environment(&account);
        let addr=signer::address_of(&account);
        Token::mint(&account,addr,100000);
    }

    #[test(account=@myAddress,alice_account=@0x11,bob_account=@0x22)]
    public fun test_transfer_and_burn(account:signer,alice_account : signer, bob_account : signer){
        setup_test_environment(&account);
        setup_test_environment(&alice_account);
        setup_test_environment(&bob_account);
        //Addresses
        let addr = signer::address_of(&account);
        let alice_addr = signer::address_of(&alice_account);
        let bob_addr = signer::address_of(&bob_account);
        //Mint
        Token::mint(&account,alice_addr,100000);
        Token::mint(&account,bob_addr,200000);
        //Checks
        assert!(Token::exact_balance(alice_addr)==100000,00);
        assert!(Token::exact_balance(bob_addr)==200000,00);
        //Transfer
        Token::transfer(&alice_account,addr,100000);
        //Checks
        assert!(Token::exact_balance(alice_addr)==0,00);
        assert!(Token::exact_balance(addr)==100000,00);
        //Burn
        Token::burn(&account,100000);
        //Check
        assert!(Token::exact_balance(addr)==0,00);

    }


}
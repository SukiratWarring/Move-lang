#[test_only]
module myAddress::counter_test{
    use std::signer;
    use std::unit_test;
    use std::vector;

    use myAddress::CounterContract;

    fun get_account():signer{
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test]
    public entry fun test_if_it_init(){
        let account=get_account();
        let addr=signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        CounterContract::init(&account);
        assert!(CounterContract::getCounter(addr)==0,42);

    }
    #[test]
    #[expected_failure]
    public entry fun test_incremnet(){
        let account=get_account();
        let addr=signer::address_of(&account);
        CounterContract::incrementCounter(&account);
        assert!(CounterContract::getCounter(addr)==1,42)
    }
}
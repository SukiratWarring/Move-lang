#[test_only]
module myAddress::counter_test{
    use std::signer;
    use std::unit_test;
    use std::vector;
    use std::debug::print;
    use myAddress::CounterContract;

    struct GlobalCounter has key{
        counter:u64
    }

    fun get_account():signer{
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }
    // Function to initialize account and setup GlobalCounter for testing
    public  fun setup_test_environment(account: &signer) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        CounterContract::init(account);
    }

    #[test]
    public entry fun test_if_it_init() {
        let account = get_account();
        setup_test_environment(&account);
        let addr = signer::address_of(&account);
        assert!(CounterContract::getCounter(addr) == 0, 42);
    }
    #[test]
    #[expected_failure]
    public fun test_incremnet_and_decrement(){
        let account=get_account();
        let addr=signer::address_of(&account);
        CounterContract::incrementCounter(&account);
        assert!(CounterContract::getCounter(addr)==1,42)
    }

    #[test]
    public fun test_decrement(){
        let account=get_account();
        setup_test_environment(&account);
        let addr = signer::address_of(&account);
        assert!(CounterContract::getCounter(addr)==0,42);
        CounterContract::incrementCounter(&account);
        assert!(CounterContract::getCounter(addr)==1,42);
        CounterContract::decrementCounter(&account);
        assert!(CounterContract::getCounter(addr)==0,42);
    }

    #[test]
    public entry fun delete(){
        let account=get_account();
        setup_test_environment(&account);
        let addr = signer::address_of(&account);
        assert!(CounterContract::getCounter(addr)==0,42);
        CounterContract::incrementCounter(&account);
        assert!(CounterContract::getCounter(addr)==1,42);
        let testValue=CounterContract::delete(&account);
        assert!(testValue==1,42);
        assert!(!exists<GlobalCounter>(addr),42);

    }
}
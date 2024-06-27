#[test_only]
module myAddress::res_acc_tests{
    use std::signer;
    use std::vector;
    use myAddress::Resource_account;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::resource_account;
    
    public entry fun setup_test_environment(resource_account: &signer,origin_account:signer,nft_receiver:&signer) {
        create_account_for_test(signer::address_of(&origin_account));
        // create a resource account from the origin account, mocking the module publishing process
        resource_account::create_resource_account(&origin_account, vector::empty<u8>(), vector::empty<u8>());
        Resource_account::init_test(resource_account);
        create_account_for_test(signer::address_of(nft_receiver));
    }    
    

    #[test(
        res_acc = @0xc3bb8488ab1a5815a9d543d7e41b0e0df46a7396f89b22821f07a4362f75ddc5,
        origin_acc = @0xcafe,
        nft_rec_acc = @0x123,
    )]
    public entry fun init(res_acc:signer,origin_acc:signer,nft_rec_acc:signer){
        setup_test_environment(&res_acc,origin_acc,&nft_rec_acc);
    }
}
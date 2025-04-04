module XWorld::profile {
    use std::bcs;
    use std::signer;
    use std::vector;
    use std::string::String;
    use aptos_std::string_utils;
    use aptos_framework::object;
    use aptos_framework::timestamp;
    

    /// Action list does not exist
    const E_ACTION_LIST_DOSE_NOT_EXIST: u64 = 1;
    /// Action does not exist
    const E_ACTION_DOSE_NOT_EXIST: u64 = 2;
    /// Action is already completed
    const E_ACTION_ALREADY_COMPLETED: u64 = 3;

    const E_ACTION_NOT_SUPPORT: u64 = 4;

      const E_ACTION_INVALID_TIME: u64 = 5;

    const ACTION_DOWNLOAD: u64 = 1;
    const ACTION_REGISTER: u64 = 2;
    const ACTION_ACTIVATE: u64 = 3;
    const ACTION_LOGIN: u64 = 4;
    const ACTION_INVITE: u64 = 5;
    const ACTION_SHARE: u64 = 6;
    const ACTION_CREATE: u64 = 7;
    const ACTION_ACHIEVEMENT: u64 = 8;
    const ACTION_CONSUMER: u64 = 9;


    struct UserActionListCounter has key {
        counter: u64,
        counter_at: u64,
    }

    struct ActionList has key {
        owner: address,
        actes: vector<Action>,
    }

    struct Action has store, drop, copy {
        act : u64,
        acted_at: u64,
        content: String,
    }

    // This function is only called once when the module is published for the first time.
    // init_module is optional, you can also have an entry function as the initializer.
    fun init_module(_module_publisher: &signer) {
        // nothing to do here
    }

    // ======================== Write functions ========================

    public entry fun create_action_list(sender: &signer) acquires UserActionListCounter {
        let sender_address = signer::address_of(sender);
        let counter = if (exists<UserActionListCounter>(sender_address)) {
            let counter = borrow_global<UserActionListCounter>(sender_address);
            counter.counter
        } else {
            let counter = UserActionListCounter { counter: 0, counter_at: timestamp::now_seconds()};
            move_to(sender, counter);
            0
        };
        // create a new object to hold the action list, use the contract_addr_counter as seed
        let obj_holds_action_list = object::create_named_object(
            sender,
            construct_action_list_object_seed(counter),
        );
        let obj_signer = object::generate_signer(&obj_holds_action_list);
        let action_list = ActionList {
            owner: sender_address,
            actes: vector::empty(),
        };
        // store the ActionList resource under the newly created object
        move_to(&obj_signer, action_list);
        // increment the counter
        let counter = borrow_global_mut<UserActionListCounter>(sender_address);
        counter.counter = counter.counter + 1;
        counter.counter_at = timestamp::now_seconds();
    }

    public entry fun action(sender: &signer,  action_list_idx: u64, act: u64, content: String) acquires ActionList,UserActionListCounter {
        assert!(
            (act >= ACTION_DOWNLOAD && act <= ACTION_CONSUMER),
            E_ACTION_NOT_SUPPORT
        );
        let sender_address = signer::address_of(sender);
        let action_list_obj_addr = get_action_list_obj_addr(sender_address, action_list_idx);
        assert_user_has_action_list(action_list_obj_addr);
        let counter = borrow_global<UserActionListCounter>(sender_address);
        let cur_t = timestamp::now_seconds();
        assert!(
            (cur_t >= counter.counter_at && cur_t <= counter.counter_at + 24 * 60 * 60),
            E_ACTION_INVALID_TIME
        );
        let action_list = borrow_global_mut<ActionList>(action_list_obj_addr);
        let new_action = Action {
            act,
            acted_at: timestamp::now_seconds(),
            content
        };
        vector::push_back(&mut action_list.actes, new_action);
    }
    

    // public entry fun complete_todo(sender: &signer, todo_list_idx: u64, todo_idx: u64) {
        
    // }

    // ======================== Read Functions ========================

    // Get how many action lists the sender has, return 0 if the sender has none.
    #[view]
    public fun get_action_list_counter(sender: address): (u64, u64) acquires UserActionListCounter {
        if (exists<UserActionListCounter>(sender)) {
            let counter = borrow_global<UserActionListCounter>(sender);
            (counter.counter, counter.counter_at)
        } else {
            (0, 0)
        }
    }

    #[view]
    public fun get_action_list_obj_addr(sender: address, action_list_idx: u64): address {
        object::create_object_address(&sender, construct_action_list_object_seed(action_list_idx))
    }

    #[view]
    public fun has_action_list(sender: address, action_list_idx: u64): bool {
        let action_list_obj_addr = get_action_list_obj_addr(sender, action_list_idx);
        exists<ActionList>(action_list_obj_addr)
    }

    #[view]
    public fun get_action_list(sender: address, action_list_idx: u64): (address, u64) acquires ActionList {
        let action_list_obj_addr = get_action_list_obj_addr(sender, action_list_idx);
        assert_user_has_action_list(action_list_obj_addr);
        let action_list = borrow_global<ActionList>(action_list_obj_addr);
        (action_list.owner, vector::length(&action_list.actes))
    }

    #[view]
    public fun get_action_list_by_action_list_obj_addr(action_list_obj_addr: address): (address, u64) acquires ActionList {
        let action_list = borrow_global<ActionList>(action_list_obj_addr);
        (action_list.owner, vector::length(&action_list.actes))
    }

    #[view]
    public fun get_action(sender: address, action_list_idx: u64, action_idx: u64): (u64, u64, String) acquires ActionList {
        let action_list_obj_addr = get_action_list_obj_addr(sender, action_list_idx);
        assert_user_has_action_list(action_list_obj_addr);
        let action_list = borrow_global<ActionList>(action_list_obj_addr);
        assert!(action_idx < vector::length(&action_list.actes), E_ACTION_DOSE_NOT_EXIST);
        let action_record = vector::borrow(&action_list.actes, action_idx);
        (action_record.act, action_record.acted_at, action_record.content)
    }

    // ======================== Helper Functions ========================

    fun assert_user_has_action_list(user_addr: address) {
        assert!(
            exists<ActionList>(user_addr),
            E_ACTION_LIST_DOSE_NOT_EXIST
        );
    }

    fun assert_user_has_given_action(action_list: &ActionList, action_idx: u64) {
        assert!(
            action_idx < vector::length(&action_list.actes),
            E_ACTION_DOSE_NOT_EXIST
        );
    }

    fun get_action_list_obj(sender: address, action_list_idx: u64): object::Object<ActionList> {
        let addr = get_action_list_obj_addr(sender, action_list_idx);
        object::address_to_object(addr)
    }

    fun construct_action_list_object_seed(counter: u64): vector<u8> {
        // The seed must be unique per action list creator
        //Wwe add contract address as part of the seed so seed from 2 action list contract for same user would be different
        bcs::to_bytes(&string_utils::format2(&b"{}_{}", @user_profile, counter))
    }

}
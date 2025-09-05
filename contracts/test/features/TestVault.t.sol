function setUp() public {
    token = new MockERC20();
    address[] memory proposers = new address[](1);
    address[] memory executors = new address[](1);
    proposers[0] = owner;
    executors[0] = owner;
    timelock = new TimelockController(1 days, proposers, executors, owner);
    controller = new TestController(address(token), owner, address(timelock));
    token.mint(address(controller), 1 ether);
    strategy = new MockStrategy(address(token));
    vm.prank(owner);
    controller.proposeStrategy(address(strategy));
    vm.prank(owner);
    timelock.schedule(
        address(controller),
        0,
        abi.encodeWithSelector(controller.addStrategy.selector, address(strategy)),
        bytes32(0),
        bytes32(0),
        1 days
    );
    vm.warp(block.timestamp + 1 days + 1);
    vm.prank(owner);
    timelock.execute(
        address(controller),
        0,
        abi.encodeWithSelector(controller.addStrategy.selector, address(strategy)),
        bytes32(0),
        bytes32(0)
    );
    vault = new TestVault(token, controller);
    token.mint(address(this), 100 ether);
    token.approve(address(vault), 100 ether);
}

function test_maliciousStrategy_steals_funds_users_loss() public {
    MaliciousStrategy malicious = new MaliciousStrategy(address(token));
    vm.prank(owner);
    controller.proposeStrategy(address(malicious));
    vm.warp(block.timestamp + 1 days + 1);
    vm.prank(owner);
    vm.expectRevert("Strategy deposit failed");
    timelock.execute(
        address(controller),
        0,
        abi.encodeWithSelector(controller.addStrategy.selector, address(malicious)),
        bytes32(0),
        bytes32(0)
    );
}

function test_depositWithdrawMultiStrategy() public {
    address strategy2 = address(new MockStrategy(address(token)));
    vm.prank(owner);
    controller.proposeStrategy(strategy2);
    vm.warp(block.timestamp + 1 days + 1);
    vm.prank(owner);
    timelock.execute(
        address(controller),
        0,
        abi.encodeWithSelector(controller.addStrategy.selector, strategy2),
        bytes32(0),
        bytes32(0)
    );
    vault.deposit(50 ether, address(strategy));
    vault.deposit(50 ether, strategy2);
    assertEq(vault.getUserBalance(address(this), address(strategy)), 50 ether);
    assertEq(vault.getUserBalance(address(this), strategy2), 50 ether);
    vault.withdraw(25 ether, address(strategy));
    assertEq(vault.getUserBalance(address(this), address(strategy)), 25 ether);
}
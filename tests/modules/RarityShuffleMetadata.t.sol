// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import { RarityShuffleMetadata } from "@modules/RarityShuffleMetadata.sol";
import { IRarityShuffleMetadata } from "@modules/interfaces/IRarityShuffleMetadata.sol";

error LogError(uint256, uint256, uint256, uint256);
error USED(uint256 id, uint256 by, uint256 curr);

contract RarityShuffleMetadataTests is Test{
    struct Offset {
        bool used;
        uint256 by;
    }
  
  mapping (uint256 => Offset) usedOffset;

  RarityShuffleMetadata module;
  
    address contractCreator;
    address anyone;

    uint256[] _ranges;

    function setUp() public {

        contractCreator = vm.addr(1);
        anyone = vm.addr(2);

        _ranges.push(0);
        _ranges.push(60);
        _ranges.push(120);
        _ranges.push(180);
        _ranges.push(220);
        _ranges.push(260);
        _ranges.push(300);
        _ranges.push(330);
        _ranges.push(360);
        _ranges.push(390);
        _ranges.push(416);
        _ranges.push(432);
        _ranges.push(440);

        module = new RarityShuffleMetadata(
          contractCreator,
          444,
          13,
          _ranges
        );
    }
    
    function test_setupFailsIfRangeOutOfOrder() public {
        uint256[] memory _ranges = new uint256[](6);
        _ranges[0] = 0;
        _ranges[1] = 25;
        _ranges[2] = 10;
        _ranges[3] = 50;
        _ranges[4] = 80;
        _ranges[5] = 95;

        vm.expectRevert(IRarityShuffleMetadata.RangeMustBeOrdered.selector);
        new RarityShuffleMetadata(
          contractCreator,
          100,
          6,
          _ranges
        );

    }
    
    function test_bst(uint256 offset) public {
        uint256 shuffleId = module.getBucketByOffset(offset);
        assertTrue(shuffleId <= 13);
        
        if (offset < 60) assertEq(shuffleId, 1);
        else if (offset < 120) assertEq(shuffleId, 2);
        else if (offset < 180) assertEq(shuffleId, 3);
        else if (offset < 220) assertEq(shuffleId, 4);
        else if (offset < 260) assertEq(shuffleId, 5);
        else if (offset < 300) assertEq(shuffleId, 6);
        else if (offset < 330) assertEq(shuffleId, 7);
        else if (offset < 360) assertEq(shuffleId, 8);
        else if (offset < 390) assertEq(shuffleId, 9);
        else if (offset < 416) assertEq(shuffleId, 10);
        else if (offset < 432) assertEq(shuffleId, 11);
        else if (offset < 440) assertEq(shuffleId, 12);
        else assertEq(shuffleId, 13);
    }
    
    function test_OnlyEditionCanTrigger() public {
      vm.startPrank(anyone);
      
      vm.expectRevert(IRarityShuffleMetadata.OnlyEditionCanTrigger.selector);
      module.triggerMetadata(100);
      
      vm.stopPrank();
    }
    
    function test_TriggerFailsIfExceedsEditionsAvailable() public {
      vm.startPrank(contractCreator);

      vm.expectRevert(IRarityShuffleMetadata.NoEditionsRemain.selector);
      module.triggerMetadata(445);
      
      vm.stopPrank();
      
    }
    
    function test_triggerMetadata() public {
      vm.startPrank(contractCreator);

      module.triggerMetadata(100);
      module.triggerMetadata(100);
      module.triggerMetadata(100);
      module.triggerMetadata(100);
      module.triggerMetadata(44);
      
      for (uint256 index = 1; index <= 444; index++) {
        uint256 offset = module.offsets(index);
        // assertFalse(usedOffset[offset]);
          if (usedOffset[offset].used) revert USED(offset, usedOffset[offset].by, index);
        assertTrue(offset < 444);
        
          usedOffset[offset] = Offset(true, index);
        
        uint256 shuffleId = module.getBucketByOffset(offset);
        assertTrue(shuffleId <= 13);
        assertTrue(shuffleId >= 1);
        
        if (offset < 60) assertEq(shuffleId, 1);
        else if (offset < 120) assertEq(shuffleId, 2);
        else if (offset < 180) assertEq(shuffleId, 3);
        else if (offset < 220) assertEq(shuffleId, 4);
        else if (offset < 260) assertEq(shuffleId, 5);
        else if (offset < 300) assertEq(shuffleId, 6);
        else if (offset < 330) assertEq(shuffleId, 7);
        else if (offset < 360) assertEq(shuffleId, 8);
        else if (offset < 390) assertEq(shuffleId, 9);
        else if (offset < 416) assertEq(shuffleId, 10);
        else if (offset < 432) assertEq(shuffleId, 11);
        else if (offset < 440) assertEq(shuffleId, 12);
        else assertEq(shuffleId, 13);
      }
      
      vm.stopPrank();
    }
    
    function testExample() public {
        vm.startPrank(address(0xB0B));
        assertTrue(true);
    }

}

// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.17;

// Parameter signature: PRC
library Percent {
    uint256 public constant MAXVALUE = SCALE;
    uint256 public constant SCALE = 10**10; // Precision up to 10 decimal places (10^10)

    // Method to apply a percentage to a number with 10 decimal places of precision
    function applyToNumber(uint256 value, uint256 percent)
        public
        pure
        returns (uint256)
    {
        require(percent >= 0, "C5"); // Ensure percent is non-negative
        require(percent < MAXVALUE, "C5");

        // Multiply the value by SCALE to adjust for precision
        uint256 scaledValue = value * SCALE;

        // Apply the percentage and return the result
        return (scaledValue * percent) / (SCALE);
    }

    // WARNING: The number must be scaled by SCALE.
    // For example, if the number is 10.5, it will be 10500000000000000000 == 10.5*10^10 (10.5 * SCALE).
}

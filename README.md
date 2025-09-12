# Cross chain Rebase Token 
1. A protocol that allows user to deposit into a vault and in return, receiver rebase token that represent thein underlying balance 

2. Rebase token --> balanceOf function is dynamic to show the changing balance with time .
    - Balance increase linearly with time 
    - Mint tokens to our users every time they perform an action (minting, burning, transferring, or... bridging)

3. Interest rate 
    - Individually set an interest rate on each user based on some global interest rate of the protocol at the same time the user depositis into the vault.
    - The gloval interest rate can onluy decrease to incetivise / reward early adopters.
    - this is going to increase token adoption 


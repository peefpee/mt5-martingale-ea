# MartingaleRSI_EA for MetaTrader 5

**Author:** pfp  
**Date:** June 19, 2025  
**License:** MIT License

## Overview

Martingale EA is a MetaTrader 5 Expert Advisor (EA) designed to automate a martingale-based trading strategy using RSI (Relative Strength Index) as the entry filter. This EA initiates trades when the RSI crosses key levels, and scales into positions using a martingale system with dynamic take-profit (TP) recalculations.

It is ideal for traders who want to explore grid/martingale mechanics enhanced by technical confirmation from RSI.

It is NOT a HOLY GRAIL OF TRADING.

---

## Features

- **RSI-based Entry:**  
  Long positions are triggered when RSI crosses above 50, and shorts when RSI falls below 50.

- **Martingale Position Sizing:**  
  Subsequent trades increase in lot size by a configurable multiplier when floating loss criteria are met.

- **Configurable Entry Spacing:**  
  Control how many points away each new martingale trade should open.

- **Dynamic TP Calculation:**  
  Take-profit is updated as new trades are added, aiming for a net basket profit.

- **One-Way Exposure:**  
  Only trades in one direction at a time (either all buys or all sells).

---

## Parameters

- `LotSize`: Starting lot size of the first trade (e.g., 0.01).
- `Multiplier`: Multiplier for lot size on each subsequent trade (e.g., 1.5).
- `RSI_Period`: RSI indicator period (e.g., 14).
- `EntrySpacingPips`: Distance in points between consecutive trades (e.g., 200).

---

## Installation

1. Copy `MartingaleRSI_EA.mq5` to your MetaTrader 5 `Experts` directory.
2. Compile the `.mq5` file using the MetaEditor.
3. Attach the compiled EA (`.ex5`) to any chart in your MT5 terminal.
4. Enable AutoTrading.

---

## Disclaimer

⚠️ **Use at your own risk.** Martingale strategies carry inherent risk of account drawdown or total loss if not properly managed. This EA is provided for educational and research purposes. Test thoroughly on demo accounts before deploying to live trading.
It is NOT a HOLY GRAIL OF TRADING. USE WITH CAUTION ON LIVE ACCOUNTS, THIS EA IS ONLY FOR ENTERTAINMENT PURPOSES

---

## License

This project is licensed under the MIT License. See the License file for more details.



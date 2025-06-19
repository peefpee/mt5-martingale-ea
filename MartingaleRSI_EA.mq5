//+------------------------------------------------------------------+
//|                                          RSI_Martingale_EA.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

// Input parameters
input group "=== RSI Settings ==="
input int RSI_Period = 14;                    // RSI Period
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;  // RSI Applied Price
input double RSI_Overbought = 70;             // RSI Overbought level (sell signal)
input double RSI_Oversold = 30;               // RSI Oversold level (buy signal)

input group "=== Martingale Settings ==="
input double FirstLotSize = 0.01;             // First lot size
input double Multiplier = 2.0;                // Lot size multiplier
input int PointDifference = 200;              // Point difference for next entry
input double TakeProfit = 100;                // Take profit in points

input group "=== General Settings ==="
input int MagicNumber = 12345;                // Magic number
input string Comment = "RSI Martingale";      // Order comment

// Global variables
CTrade trade;
int rsiHandle;
double rsiBuffer[];
datetime lastBarTime;
int currentSequence = 0;
ENUM_ORDER_TYPE currentDirection = -1;
double lastEntryPrice = 0;
double currentLotSize = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize RSI indicator
    rsiHandle = iRSI(_Symbol, _Period, RSI_Period, RSI_Price);
    if(rsiHandle == INVALID_HANDLE)
    {
        Print("Failed to create RSI indicator handle");
        return INIT_FAILED;
    }
    
    // Set trade parameters
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    ArraySetAsSeries(rsiBuffer, true);
    
    Print("RSI Martingale EA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(rsiHandle != INVALID_HANDLE)
        IndicatorRelease(rsiHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check current positions on every tick
    CheckCurrentPositions();
    
    // Check for martingale entry on every tick if sequence is active
    if(currentSequence > 0)
    {
        CheckMartingaleEntry();
        return; // Skip new sequence logic if already in a sequence
    }
    
    // Only check for new sequence entry on new bar
    if(!IsNewBar())
        return;
    
    // Get RSI values for new sequence entry
    if(CopyBuffer(rsiHandle, 0, 0, 2, rsiBuffer) < 2)
        return;
    
    double currentRSI = rsiBuffer[0];
    
    // Determine entry signals for new sequence
    bool buySignal = currentRSI < RSI_Oversold;   // Buy when oversold
    bool sellSignal = currentRSI > RSI_Overbought; // Sell when overbought
    
    // Start new sequence if no active sequence
    if(currentSequence == 0)
    {
        if(buySignal)
            StartNewSequence(ORDER_TYPE_BUY);
        else if(sellSignal)
            StartNewSequence(ORDER_TYPE_SELL);
    }
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    if(currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check current positions                                          |
//+------------------------------------------------------------------+
void CheckCurrentPositions()
{
    int totalPositions = 0;
    currentDirection = -1;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionGetTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                totalPositions++;
                currentDirection = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
            }
        }
    }
    
    if(totalPositions == 0)
    {
        currentSequence = 0;
        currentLotSize = FirstLotSize;
        lastEntryPrice = 0;
    }
    else
    {
        currentSequence = totalPositions;
    }
}

//+------------------------------------------------------------------+
//| Start new martingale sequence                                    |
//+------------------------------------------------------------------+
void StartNewSequence(ENUM_ORDER_TYPE orderType)
{
    double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                                                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double tp = CalculateTakeProfit(orderType, price, FirstLotSize);
    
    if(orderType == ORDER_TYPE_BUY)
    {
        if(trade.Buy(FirstLotSize, _Symbol, price, 0, tp, Comment))
        {
            currentSequence = 1;
            currentDirection = ORDER_TYPE_BUY;
            lastEntryPrice = price;
            currentLotSize = FirstLotSize;
            Print("Started new BUY sequence at ", price);
        }
    }
    else
    {
        if(trade.Sell(FirstLotSize, _Symbol, price, 0, tp, Comment))
        {
            currentSequence = 1;
            currentDirection = ORDER_TYPE_SELL;
            lastEntryPrice = price;
            currentLotSize = FirstLotSize;
            Print("Started new SELL sequence at ", price);
        }
    }
}

//+------------------------------------------------------------------+
//| Check for martingale entry                                       |
//+------------------------------------------------------------------+
void CheckMartingaleEntry()
{
    if(currentDirection == -1 || lastEntryPrice == 0)
        return;
    
    double currentPrice = (currentDirection == ORDER_TYPE_BUY) ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double pointDiff = PointDifference * _Point;
    bool shouldAddPosition = false;
    
    if(currentDirection == ORDER_TYPE_BUY)
    {
        // Add buy position if price moved down by PointDifference
        shouldAddPosition = (lastEntryPrice - currentPrice) >= pointDiff;
    }
    else
    {
        // Add sell position if price moved up by PointDifference
        shouldAddPosition = (currentPrice - lastEntryPrice) >= pointDiff;
    }
    
    if(shouldAddPosition)
    {
        AddMartingalePosition();
    }
}

//+------------------------------------------------------------------+
//| Add martingale position                                          |
//+------------------------------------------------------------------+
void AddMartingalePosition()
{
    double newLotSize = NormalizeDouble(currentLotSize * Multiplier, 2);
    double price = (currentDirection == ORDER_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(currentDirection == ORDER_TYPE_BUY)
    {
        if(trade.Buy(newLotSize, _Symbol, price, 0, 0, Comment))
        {
            currentSequence++;
            lastEntryPrice = price;
            currentLotSize = newLotSize;
            UpdateAllTakeProfits();
            Print("Added BUY position #", currentSequence, " with lot size ", newLotSize);
        }
    }
    else
    {
        if(trade.Sell(newLotSize, _Symbol, price, 0, 0, Comment))
        {
            currentSequence++;
            lastEntryPrice = price;
            currentLotSize = newLotSize;
            UpdateAllTakeProfits();
            Print("Added SELL position #", currentSequence, " with lot size ", newLotSize);
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate take profit for all positions                         |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE orderType, double referencePrice, double totalLots)
{
    double tpPoints = TakeProfit * _Point;
    
    if(orderType == ORDER_TYPE_BUY)
        return referencePrice + tpPoints;
    else
        return referencePrice - tpPoints;
}

//+------------------------------------------------------------------+
//| Update take profit for all positions                            |
//+------------------------------------------------------------------+
void UpdateAllTakeProfits()
{
    double totalLots = 0;
    double weightedPrice = 0;
    int positionCount = 0;
    
    // Calculate average entry price weighted by lot size
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionGetTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                double posLots = PositionGetDouble(POSITION_VOLUME);
                double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                
                totalLots += posLots;
                weightedPrice += posPrice * posLots;
                positionCount++;
            }
        }
    }
    
    if(totalLots > 0)
    {
        double avgPrice = weightedPrice / totalLots;
        double newTP = CalculateTakeProfit(currentDirection, avgPrice, totalLots);
        
        // Update TP for all positions
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if(PositionGetTicket(i))
            {
                if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
                   PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                {
                    ulong ticket = PositionGetTicket(i);
                    trade.PositionModify(ticket, 0, newTP);
                }
            }
        }
        
        Print("Updated TP for all positions to ", newTP, " (Avg price: ", avgPrice, ")");
    }
}
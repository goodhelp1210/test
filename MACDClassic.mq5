//+------------------------------------------------------------------+
//|                                                  MACDClassic.mqh |
//|                                                      Paul Csapak |
//|                 https://github.com/paulcpk/mql5-MT5-MACD-Classic |
//+------------------------------------------------------------------+

#property copyright "Paul Csapak"
#property link "https://github.com/paulcpk/mql5-MT5-MACD-Classic"
#property description "Moving Average Convergence/Divergence (Classic)"

/*
MIT License

Copyright (c) 2020 Paul Csapak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <MovingAverages.mqh>

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots 3

#property indicator_label1 "MACD"
#property indicator_type1 DRAW_LINE
#property indicator_color1 Blue
#property indicator_style1  STYLE_SOLID
#property indicator_width1 1

#property indicator_label2 "Signal"
#property indicator_type2 DRAW_LINE
#property indicator_color2 Red
#property indicator_style2  STYLE_SOLID
#property indicator_width2 1

#property indicator_label3  "Histogram"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  Green
#property indicator_style3  STYLE_SOLID
#property indicator_width3  4

//--- input parameters
input int InpFastEMA = 12;                              // Fast EMA period
input int InpSlowEMA = 26;                              // Slow EMA period
input int InpSignalSMA = 9;                             // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price
//--- indicator buffers
double ExtMacdBuffer[];
double ExtSignalBuffer[];
double ExtFastMaBuffer[];
double ExtSlowMaBuffer[];
double ExtHistogBuffer[];
//--- MA handles
int ExtFastMaHandle;
int ExtSlowMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
    //--- indicator buffers mapping
    SetIndexBuffer(0, ExtMacdBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ExtSignalBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, ExtHistogBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, ExtFastMaBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, ExtSlowMaBuffer, INDICATOR_CALCULATIONS);
    //--- sets first bar from what index will be drawn
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpSignalSMA - 1);
    //--- name for indicator subwindow label
    IndicatorSetString(INDICATOR_SHORTNAME, "MACDClassic(" + string(InpFastEMA) + "," + string(InpSlowEMA) + "," + string(InpSignalSMA) + ")");
    //--- get MA handles
    ExtFastMaHandle = iMA(NULL, 0, InpFastEMA, 0, MODE_EMA, InpAppliedPrice);
    ExtSlowMaHandle = iMA(NULL, 0, InpSlowEMA, 0, MODE_EMA, InpAppliedPrice);
    //--- initialization done
}
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    //--- check for data
    if (rates_total < InpSignalSMA)
        return (0);
    //--- not all data may be calculated
    int calculated = BarsCalculated(ExtFastMaHandle);
    if (calculated < rates_total)
    {
        Print("Not all data of ExtFastMaHandle is calculated (", calculated, "bars ). Error", GetLastError());
        return (0);
    }
    calculated = BarsCalculated(ExtSlowMaHandle);
    if (calculated < rates_total)
    {
        Print("Not all data of ExtSlowMaHandle is calculated (", calculated, "bars ). Error", GetLastError());
        return (0);
    }
    //--- we can copy not all data
    int to_copy;
    if (prev_calculated > rates_total || prev_calculated < 0)
        to_copy = rates_total;
    else
    {
        to_copy = rates_total - prev_calculated;
        if (prev_calculated > 0)
            to_copy++;
    }
    //--- get Fast EMA buffer
    if (IsStopped())
        return (0); //Checking for stop flag
    if (CopyBuffer(ExtFastMaHandle, 0, 0, to_copy, ExtFastMaBuffer) <= 0)
    {
        Print("Getting fast EMA is failed! Error", GetLastError());
        return (0);
    }
    //--- get SlowSMA buffer
    if (IsStopped())
        return (0); //Checking for stop flag
    if (CopyBuffer(ExtSlowMaHandle, 0, 0, to_copy, ExtSlowMaBuffer) <= 0)
    {
        Print("Getting slow SMA is failed! Error", GetLastError());
        return (0);
    }
    //---
    int limit;
    if (prev_calculated == 0)
        limit = 0;
    else
        limit = prev_calculated - 1;
    //--- calculate MACD
    for (int i = limit; i < rates_total && !IsStopped(); i++)
        ExtMacdBuffer[i] = ExtFastMaBuffer[i] - ExtSlowMaBuffer[i];
    //--- calculate Signal
    ExponentialMAOnBuffer(rates_total, prev_calculated, 0, InpSignalSMA, ExtMacdBuffer, ExtSignalBuffer);

    //--- calculate Histogram
   for(int i=limit;i<rates_total && !IsStopped();i++)
      ExtHistogBuffer[i]=ExtMacdBuffer[i]-ExtSignalBuffer[i];
    //--- OnCalculate done. Return new prev_calculated.
    return (rates_total);
}
//+------------------------------------------------------------------+

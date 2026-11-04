//+------------------------------------------------------------------+
//| AbsorptionRadar.mq5                                              |
//| Smart Money Absorption Radar | Thomas - MetaTrader 5 port        |
//| MT5 adaptation: AlgoToolbox (atoskueko)                          |
//+------------------------------------------------------------------+
// SPDX-License-Identifier: MPL-2.0
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// ORIGINAL WORK
// Smart Money Absorption Radar | Thomas, Pine Script v6.
// (c) Thomas-Sterling
// Original publication: TradingView, "Smart Money Absorption Radar | Thomas".
//
// MT5 ADAPTATION AND MODIFICATIONS
// Copyright 2026 AlgoToolbox (atoskueko).
// https://algotoolbox.com | https://t.me/algotoolbox
// The adaptation credit does not claim authorship of the original work
// or imply endorsement by its author.
//
// PURPOSE AND SCOPE
// Volume-spike + rejection-wick "absorption" candles, optional EMA trend
// and liquidity-sweep filters, signal cooldown, latest buyer / seller
// absorption zone, BUY / SELL markers, ATR-based Entry / SL / TP1-TP3
// auto targets and a radar dashboard. Analysis indicator only; it does
// not place, modify or close orders.
//
// EXECUTION AND PRESENTATION
// - All signal state is committed on completed bars only (Pine
//   barstate.isconfirmed). The forming bar is never evaluated.
// - MT5 has no universal real volume for FX/CFD symbols: the volume
//   source is selectable (tick volume default, real volume optional).
//   Pine's "estimated absorption" caveat applies equally here.
// - SMA(volume), EMA and ATR (RMA of true range) are computed natively;
//   seeds follow Pine conventions, bit-exact parity is not asserted.
// - As in the original only the LATEST bull zone, bear zone and target
//   set are kept on the chart. Arrow buffers keep every signal and sweep
//   visible in history and readable by an EA through iCustom.
// - Buffers: 0 EMA, 1 Buy, 2 Sell, 3 Bull sweep, 4 Bear sweep,
//   5 Entry, 6 SL, 7 TP1, 8 TP2, 9 TP3 (levels persist until the next
//   signal, 0 before the first one).
// - Dashboard is drawn top-left (AlgoToolbox port convention) and
//   reflects the last completed bar.
//
// DISTRIBUTION
// Retain the original notices and MPL-2.0 terms for covered source and
// modifications. When distributing a compiled port, inform recipients
// how to obtain the corresponding covered source under MPL-2.0.
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, atoskueko / AlgoToolbox.com"
#property link        "https://algotoolbox.com"
#property version     "1.00"
#property description "Absorption Radar: MT5 port of Smart Money Absorption Radar | Thomas. Volume spike + rejection wick"
#property description "absorption signals, liquidity sweeps, EMA filter, absorption zones, ATR Entry/SL/TP1-3, dashboard."
#property strict
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   5

#property indicator_label1  "Trend EMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_width1  2
#property indicator_label2  "BUY Absorption"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  C'0,150,120'
#property indicator_width2  2
#property indicator_label3  "SELL Absorption"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  C'200,55,65'
#property indicator_width3  2
#property indicator_label4  "Bullish Liquidity Sweep"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrAqua
#property indicator_width4  1
#property indicator_label5  "Bearish Liquidity Sweep"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrOrange
#property indicator_width5  1

#define TAG "[SAR]"
#define PFX "SAR_"

enum SAR_VOLUME { SAR_TICK_VOLUME=0, SAR_REAL_VOLUME=1 };

input group "00 - About"
input string InpAbout        = "Port by AlgoToolbox.com - original by Thomas-Sterling (MPL-2.0)"; // About
input string InpInfoTelegram = "https://t.me/algotoolbox";               // Telegram
input string InpInfoHomepage = "https://algotoolbox.com";                // Homepage
input string InpInfoBroker   = "https://one.toexness.com/a/ja854feiyo";  // Broker (affiliate link)

input group "01 - Absorption Engine"
input SAR_VOLUME InpVolumeSource = SAR_TICK_VOLUME; // Volume Source (MT5: tick volume for FX/CFD)
input int    volLength     = 20;    // Volume Average Length
input double volMultiplier = 1.5;   // Volume Spike Multiplier
input double wickRatio     = 0.40;  // Minimum Rejection Wick Ratio
input int    rangeLength   = 20;    // Liquidity Lookback

input group "02 - Signal Filters"
input bool   useTrendFilter = false; // Use EMA Trend Filter
input int    emaLength      = 200;   // EMA Length
input bool   useSweepFilter = false; // Require Liquidity Sweep
input int    cooldown       = 8;     // Signal Cooldown Bars

input group "03 - Chart Visuals"
input bool   showZones     = true;  // Show Absorption Zones
input bool   showSweep     = true;  // Show Liquidity Sweeps
input bool   showEMA       = false; // Show EMA
input bool   showSignals   = true;  // Show BUY / SELL Signals
input int    zoneExtension = 20;    // Zone Extension Bars
input int    InpZoneTransp = 87;    // Zone transparency (0-100)

input group "04 - Auto Targets"
input bool   showTargets     = true; // Show Auto Targets
input double targetATR       = 1.5;  // Stop Loss ATR Multiplier
input double targetRR1       = 1.0;  // TP1 Risk Reward
input double targetRR2       = 2.0;  // TP2 Risk Reward
input double targetRR3       = 3.0;  // TP3 Risk Reward
input int    targetExtension = 20;   // Target Line Extension

input group "05 - Radar Dashboard"
input bool   showDashboard = true;   // Show Dashboard

input group "06 - Alerts (closed bar)"
input bool   InpAlertSignals = false; // Buyer / Seller absorption alerts
input bool   InpAlertSweeps  = false; // Liquidity sweep alerts
input bool   InpAlertVolume  = false; // Volume spike alerts
input bool   InpPush         = false; // Also send push notifications

//--- buffers
double bEma[], bBuy[], bSell[], bSweepUp[], bSweepDn[], bEntry[], bSL[], bTP1[], bTP2[], bTP3[];

//--- persistent state (Pine var)
int    lastSignalBar=-1;                       // var int lastSignalBar
string lastEvent="WAITING";                    // var string lastEvent
double autoEntry=0, autoSL=0, autoTP1=0, autoTP2=0, autoTP3=0;
double emaPrev=0; double atrPrev=0; int atrSeeded=0; double trSum=0;
bool   lastVolSpike=false, lastBullAbs=false, lastBearAbs=false; double lastClose=0, lastEma=0;
int    processed=-1; datetime gLastAlertBar=0;

//--- drawing helpers ---------------------------------------------------
void TLine(const string id,const datetime t1,const double p1,const datetime t2,const double p2,const color col,const int width,const bool ray)
  {
   string nm=PFX+id;
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); ObjectSetInteger(0,nm,OBJPROP_BACK,true); }
   ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1); ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2); ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,col); ObjectSetInteger(0,nm,OBJPROP_WIDTH,width); ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_SOLID); ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
  }
void TText(const string id,const datetime t,const double p,const string txt,const color col,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT,const int pt=8)
  {
   string nm=PFX+id;
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_TEXT,0,t,p); ObjectSetString(0,nm,OBJPROP_FONT,"Consolas"); ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,pt); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); }
   ObjectSetInteger(0,nm,OBJPROP_TIME,0,t); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p); ObjectSetString(0,nm,OBJPROP_TEXT,txt); ObjectSetInteger(0,nm,OBJPROP_COLOR,col); ObjectSetInteger(0,nm,OBJPROP_ANCHOR,anchor);
  }
color gBg=clrBlack;
color Blend(const color c,const double transp)   // fake alpha: mix with the chart background
  {
   double t=MathMax(0,MathMin(100,transp))/100.0;
   int r=(int)MathRound(((c)&0xFF)*(1-t)+((gBg)&0xFF)*t);
   int g=(int)MathRound(((c>>8)&0xFF)*(1-t)+((gBg>>8)&0xFF)*t);
   int b=(int)MathRound(((c>>16)&0xFF)*(1-t)+((gBg>>16)&0xFF)*t);
   return((color)(r|(g<<8)|(b<<16)));
  }
void Rect(const string nm,const datetime t1,const double p1,const datetime t2,const double p2,const color c,const bool fill)
  {
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,p1,t2,p2); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); ObjectSetInteger(0,nm,OBJPROP_BACK,true); }
   ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1); ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2); ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,c); ObjectSetInteger(0,nm,OBJPROP_FILL,fill); ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);
  }
void Box(const string id,const datetime t1,const double top,const datetime t2,const double bottom,const color col,const string txt)   // blended fill + border (alpha 15 in Pine) + label
  {
   Rect(PFX+id+"_F",t1,top,t2,bottom,Blend(col,InpZoneTransp),true);
   Rect(PFX+id+"_B",t1,top,t2,bottom,Blend(col,15),false);
   TText(id+"_t",t1,(top+bottom)/2.0," "+txt,col,ANCHOR_LEFT,7);
  }
void Kill(const string id){ string nm=PFX+id; if(ObjectFind(0,nm)>=0) ObjectDelete(0,nm); }
void KillBox(const string id){ Kill(id+"_F"); Kill(id+"_B"); Kill(id+"_t"); }
datetime Ahead(const datetime t,const int bars){ return t+(datetime)bars*PeriodSeconds(); }
string Px(const double p){ return DoubleToString(p,_Digits); }

//--- dashboard (TradingView table look, top-left) ----------------------
#define DW 244
#define DROW 22
#define DX 8
#define DY 22
color cWhite=clrWhite, cHead=C'20,30,48', cCell=C'30,30,30', cGrid=C'60,60,60', cAqua=clrAqua;
color cGreenBg=C'0,110,40', cRedBg=C'140,30,30', cOrangeBg=C'180,110,0', cGrayBg=C'70,70,70', cBlueBg=C'30,50,120';
void DRect(const string id,const int x,const int y,const int w,const int h,const color bgc,const color bc)
  {
   string nm=PFX+"D_"+id;
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,nm,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,nm,OBJPROP_BACK,false); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,nm,OBJPROP_XSIZE,w); ObjectSetInteger(0,nm,OBJPROP_YSIZE,h); }
   if((color)ObjectGetInteger(0,nm,OBJPROP_BGCOLOR)!=bgc) ObjectSetInteger(0,nm,OBJPROP_BGCOLOR,bgc);
   if((color)ObjectGetInteger(0,nm,OBJPROP_COLOR)!=bc) ObjectSetInteger(0,nm,OBJPROP_COLOR,bc);
  }
void DCell(const string id,const int row,const int col,const string txt,const color c,const int pt=9)   // col 0 = left, 1 = right; text centred
  {
   string nm=PFX+"D_"+id; int cx=DX+(DW/4)*(col==0 ? 1 : 3);
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_LABEL,0,0,0); ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_UPPER); ObjectSetString(0,nm,OBJPROP_FONT,"Arial"); ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,pt); ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,cx); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,DY+row*DROW+4); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); }
   if(ObjectGetString(0,nm,OBJPROP_TEXT)!=txt) ObjectSetString(0,nm,OBJPROP_TEXT,txt);
   if((color)ObjectGetInteger(0,nm,OBJPROP_COLOR)!=c) ObjectSetInteger(0,nm,OBJPROP_COLOR,c);
  }
void Dashboard()
  {
   if(!showDashboard) return;
   const int rows=7;
   // right-column cell backgrounds (Pine colours the value cells)
   DRect("BG",DX,DY,DW,rows*DROW,cCell,cGrid);
   DRect("HD",DX,DY,DW,DROW,cHead,cGrid);
   DRect("V1",DX+DW/2,DY+1*DROW,DW/2,DROW,lastVolSpike ? cOrangeBg : cGrayBg,cGrid);
   DRect("V2",DX+DW/2,DY+2*DROW,DW/2,DROW,lastBullAbs ? cGreenBg : cGrayBg,cGrid);
   DRect("V3",DX+DW/2,DY+3*DROW,DW/2,DROW,lastBearAbs ? cRedBg : cGrayBg,cGrid);
   DRect("V4",DX+DW/2,DY+4*DROW,DW/2,DROW,lastBullAbs ? cGreenBg : lastBearAbs ? cRedBg : cGrayBg,cGrid);
   DRect("V5",DX+DW/2,DY+5*DROW,DW/2,DROW,lastClose>lastEma ? cGreenBg : cRedBg,cGrid);
   DRect("V6",DX+DW/2,DY+6*DROW,DW/2,DROW,cBlueBg,cGrid);
   DRect("H6",DX,DY+6*DROW,DW/2,DROW,cHead,cGrid);
   for(int r=1;r<rows;r++) DRect("G"+IntegerToString(r),DX,DY+r*DROW,DW,1,cGrid,cGrid);
   DRect("GV",DX+DW/2,DY,1,rows*DROW,cGrid,cGrid);
   DCell("T0",0,0,"ABSORPTION RADAR",cWhite); DCell("T1",0,1,"MT5",cAqua);
   DCell("A0",1,0,"Volume",cWhite);        DCell("A1",1,1,lastVolSpike ? "HIGH VOLUME" : "NORMAL",cWhite);
   DCell("B0",2,0,"Buy Pressure",cWhite);  DCell("B1",2,1,lastBullAbs ? "DETECTED" : "NOT DETECTED",cWhite);
   DCell("C0",3,0,"Sell Pressure",cWhite); DCell("C1",3,1,lastBearAbs ? "DETECTED" : "NOT DETECTED",cWhite);
   DCell("P0",4,0,"Pressure",cWhite);      DCell("P1",4,1,lastBullAbs ? "BUY PRESSURE" : lastBearAbs ? "SELL PRESSURE" : "NEUTRAL",cWhite);
   DCell("E0",5,0,"EMA Trend",cWhite);     DCell("E1",5,1,lastClose>lastEma ? "BULLISH" : lastClose<lastEma ? "BEARISH" : "NEUTRAL",cWhite);
   DCell("L0",6,0,"Last Event",cWhite);    DCell("L1",6,1,lastEvent,cWhite,8);
   // footer
   DRect("FB",DX,DY+rows*DROW+4,DW,18,cCell,cGrid);
   string nm=PFX+"D_FT";
   if(ObjectFind(0,nm)<0){ ObjectCreate(0,nm,OBJ_LABEL,0,0,0); ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_UPPER); ObjectSetString(0,nm,OBJPROP_FONT,"Arial"); ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,7); ObjectSetInteger(0,nm,OBJPROP_COLOR,cWhite); ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,DX+DW/2); ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,DY+rows*DROW+4+4); ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true); ObjectSetString(0,nm,OBJPROP_TEXT,"Port by AlgoToolbox.com"); }
  }
void Notify(const string msg){ Alert(TAG," ",msg); if(InpPush) SendNotification(TAG+" "+_Symbol+" "+StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7)+" "+msg); }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(volLength<5 || volMultiplier<1.0 || wickRatio<0.1 || wickRatio>0.9 || rangeLength<5 || emaLength<20 || cooldown<0 || zoneExtension<1 || targetATR<0.2 || targetRR1<=0 || targetRR2<=0 || targetRR3<=0 || targetExtension<5)
     { Print(TAG," invalid inputs"); return INIT_PARAMETERS_INCORRECT; }
   SetIndexBuffer(0,bEma,INDICATOR_DATA); SetIndexBuffer(1,bBuy,INDICATOR_DATA); SetIndexBuffer(2,bSell,INDICATOR_DATA);
   SetIndexBuffer(3,bSweepUp,INDICATOR_DATA); SetIndexBuffer(4,bSweepDn,INDICATOR_DATA);
   SetIndexBuffer(5,bEntry,INDICATOR_CALCULATIONS); SetIndexBuffer(6,bSL,INDICATOR_CALCULATIONS); SetIndexBuffer(7,bTP1,INDICATOR_CALCULATIONS); SetIndexBuffer(8,bTP2,INDICATOR_CALCULATIONS); SetIndexBuffer(9,bTP3,INDICATOR_CALCULATIONS);
   for(int i=0;i<5;i++) PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(1,PLOT_ARROW,233); PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,14);    // labelup  BUY
   PlotIndexSetInteger(2,PLOT_ARROW,234); PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-14);   // labeldown SELL
   PlotIndexSetInteger(3,PLOT_ARROW,225); PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,8);     // triangle up  SW
   PlotIndexSetInteger(4,PLOT_ARROW,226); PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-8);    // triangle down SW
   if(!showEMA)     PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   if(!showSignals){ PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE); PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE); }
   if(!showSweep)  { PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE); PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE); }
   IndicatorSetString(INDICATOR_SHORTNAME,"Absorption Radar");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason){ ObjectsDeleteAll(0,PFX); }
void ResetState()
  {
   lastSignalBar=-1; lastEvent="WAITING"; autoEntry=0; autoSL=0; autoTP1=0; autoTP2=0; autoTP3=0;
   emaPrev=0; atrPrev=0; atrSeeded=0; trSum=0; lastVolSpike=false; lastBullAbs=false; lastBearAbs=false; lastClose=0; lastEma=0; processed=-1;
   ObjectsDeleteAll(0,PFX);
  }
void DrawTargets(const datetime t0,const bool buy)
  {
   datetime x2=Ahead(t0,targetExtension);
   TLine("EN",t0,autoEntry,x2,autoEntry,clrBlue,2,true); TLine("SL",t0,autoSL,x2,autoSL,clrRed,2,true);
   TLine("T1",t0,autoTP1,x2,autoTP1,clrLime,1,true); TLine("T2",t0,autoTP2,x2,autoTP2,clrLime,1,true); TLine("T3",t0,autoTP3,x2,autoTP3,clrGreen,2,true);
   // labels anchored bottom-left on the price so the text sits just above its line instead of being struck through by the ray
   TText("ENt",x2,autoEntry,"ENTRY "+Px(autoEntry),clrBlue,ANCHOR_LEFT_LOWER); TText("SLt",x2,autoSL,"SL "+Px(autoSL),clrRed,ANCHOR_LEFT_LOWER);
   TText("T1t",x2,autoTP1,"TP1 "+Px(autoTP1),clrGreen,ANCHOR_LEFT_LOWER); TText("T2t",x2,autoTP2,"TP2 "+Px(autoTP2),clrGreen,ANCHOR_LEFT_LOWER); TText("T3t",x2,autoTP3,"TP3 "+Px(autoTP3),clrGreen,ANCHOR_LEFT_LOWER);
  }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
  {
   if(rates_total<MathMax(volLength,rangeLength)+3) return 0;
   int start;
   if(prev_calculated<=0 || prev_calculated>rates_total)
     {
      ResetState(); gBg=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND); start=0;
      ArrayInitialize(bEma,0); ArrayInitialize(bBuy,0); ArrayInitialize(bSell,0); ArrayInitialize(bSweepUp,0); ArrayInitialize(bSweepDn,0);
      ArrayInitialize(bEntry,0); ArrayInitialize(bSL,0); ArrayInitialize(bTP1,0); ArrayInitialize(bTP2,0); ArrayInitialize(bTP3,0);
     }
   else start=prev_calculated-1;
   const bool live=(prev_calculated>0);
   const double kEma=2.0/(emaLength+1.0);
   const double minTick=_Point;
   // ---- closed bars: committed once each --------------------------------
   for(int i=start;i<rates_total-1;i++)
     {
      if(i<=processed) continue;
      processed=i;
      // EMA (seed = first close)
      emaPrev=(i==0 ? close[0] : close[i]*kEma+emaPrev*(1-kEma)); bEma[i]=emaPrev;
      // ATR(14) = RMA(TR), SMA seed
      double tr=(i==0 ? high[0]-low[0] : MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1]))));
      if(atrSeeded<14){ trSum+=tr; atrSeeded++; atrPrev=trSum/atrSeeded; } else atrPrev=(atrPrev*13.0+tr)/14.0;
      double atr=atrPrev;
      // carry levels, clear arrows
      bEntry[i]=autoEntry; bSL[i]=autoSL; bTP1[i]=autoTP1; bTP2[i]=autoTP2; bTP3[i]=autoTP3;
      bBuy[i]=0; bSell[i]=0; bSweepUp[i]=0; bSweepDn[i]=0;
      // 02. volume and price analysis
      double vol=(InpVolumeSource==SAR_REAL_VOLUME ? (double)volume[i] : (double)tick_volume[i]);
      bool validVolume=false, volumeSpike=false;
      if(i>=volLength-1)
        {
         double sum=0; for(int k=0;k<volLength;k++) sum+=(InpVolumeSource==SAR_REAL_VOLUME ? (double)volume[i-k] : (double)tick_volume[i-k]);
         double avgVolume=sum/volLength;
         validVolume=(avgVolume>0); volumeSpike=validVolume && vol>=avgVolume*volMultiplier;
        }
      double candleRange=MathMax(high[i]-low[i],minTick);
      double upperWick=high[i]-MathMax(open[i],close[i]), lowerWick=MathMin(open[i],close[i])-low[i];
      double upperWickRatio=upperWick/candleRange, lowerWickRatio=lowerWick/candleRange, closePosition=(close[i]-low[i])/candleRange;
      bool bullRejection=lowerWickRatio>=wickRatio && closePosition>=0.60;
      bool bearRejection=upperWickRatio>=wickRatio && closePosition<=0.40;
      // 03. liquidity sweep engine (lowest/highest of the previous rangeLength bars)
      bool bullSweep=false, bearSweep=false;
      if(i>=rangeLength)
        {
         double previousLow=low[i-1], previousHigh=high[i-1];
         for(int k=2;k<=rangeLength;k++){ if(low[i-k]<previousLow) previousLow=low[i-k]; if(high[i-k]>previousHigh) previousHigh=high[i-k]; }
         bullSweep=low[i]<previousLow && close[i]>previousLow;
         bearSweep=high[i]>previousHigh && close[i]<previousHigh;
        }
      if(bullSweep) bSweepUp[i]=low[i]; if(bearSweep) bSweepDn[i]=high[i];
      // 04. absorption detection
      bool bullAbsorption=volumeSpike && bullRejection, bearAbsorption=volumeSpike && bearRejection;
      bool trendBull=!useTrendFilter || close[i]>emaPrev, trendBear=!useTrendFilter || close[i]<emaPrev;
      bool sweepBullValid=!useSweepFilter || bullSweep, sweepBearValid=!useSweepFilter || bearSweep;
      bool rawBuy=bullAbsorption && trendBull && sweepBullValid, rawSell=bearAbsorption && trendBear && sweepBearValid;
      // 05. signal cooldown
      bool cooldownPassed=(lastSignalBar<0 || i-lastSignalBar>cooldown);
      bool buySignal=rawBuy && cooldownPassed, sellSignal=rawSell && cooldownPassed;
      if(buySignal || sellSignal) lastSignalBar=i;
      // 06. absorption zones (latest per side)
      if(showZones && buySignal){ KillBox("ZB"); Box("ZB",time[i],MathMax(open[i],close[i]),Ahead(time[i],zoneExtension),low[i],clrAqua,"BUYER ABSORPTION"); }
      if(showZones && sellSignal){ KillBox("ZS"); Box("ZS",time[i],high[i],Ahead(time[i],zoneExtension),MathMin(open[i],close[i]),clrRed,"SELLER ABSORPTION"); }
      // 07. signals
      if(buySignal)  bBuy[i]=low[i];
      if(sellSignal) bSell[i]=high[i];
      // 08. dashboard state
      if(buySignal) lastEvent="BUYER ABSORPTION"; if(sellSignal) lastEvent="SELLER ABSORPTION";
      lastVolSpike=volumeSpike; lastBullAbs=bullAbsorption; lastBearAbs=bearAbsorption; lastClose=close[i]; lastEma=emaPrev;
      // 10. auto targets
      if(buySignal || sellSignal)
        {
         autoEntry=close[i]; double riskDistance=MathMax(atr*targetATR,minTick);
         if(buySignal){ autoSL=autoEntry-riskDistance; autoTP1=autoEntry+riskDistance*targetRR1; autoTP2=autoEntry+riskDistance*targetRR2; autoTP3=autoEntry+riskDistance*targetRR3; }
         else         { autoSL=autoEntry+riskDistance; autoTP1=autoEntry-riskDistance*targetRR1; autoTP2=autoEntry-riskDistance*targetRR2; autoTP3=autoEntry-riskDistance*targetRR3; }
         bEntry[i]=autoEntry; bSL[i]=autoSL; bTP1[i]=autoTP1; bTP2[i]=autoTP2; bTP3[i]=autoTP3;
         if(showTargets) DrawTargets(time[i],buySignal);
        }
      // 09. alerts: only for a bar that just closed live
      if(live && i==rates_total-2 && time[i]!=gLastAlertBar)
        {
         gLastAlertBar=time[i];
         if(InpAlertSignals && buySignal)  Notify("Buyer absorption confirmed on candle close | "+Px(close[i]));
         if(InpAlertSignals && sellSignal) Notify("Seller absorption confirmed on candle close | "+Px(close[i]));
         if(InpAlertSweeps && bullSweep)   Notify("Bullish liquidity sweep detected");
         if(InpAlertSweeps && bearSweep)   Notify("Bearish liquidity sweep detected");
         if(InpAlertVolume && volumeSpike) Notify("Volume spike detected");
        }
     }
   // ---- forming bar: EMA preview only, levels carried ------------------
   int n=rates_total-1;
   bEma[n]=close[n]*kEma+emaPrev*(1-kEma);
   bBuy[n]=0; bSell[n]=0; bSweepUp[n]=0; bSweepDn[n]=0; bEntry[n]=autoEntry; bSL[n]=autoSL; bTP1[n]=autoTP1; bTP2[n]=autoTP2; bTP3[n]=autoTP3;
   Dashboard();
   return rates_total;
  }
//+------------------------------------------------------------------+

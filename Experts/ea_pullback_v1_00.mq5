//+------------------------------------------------------------------+
//|                                            ea_pullback_v1_00.mq5 |
//| ea_pullback v1.00                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <ExpertAdvisor.mqh>

input string description1="1.-------------------------------";
input double Risk=0.1; // Risk
input int    SL        = 375; // Stop Loss distance
input int    TP        = 850; // Take Profit distance
//input int    HourStart =   7; // Hour of trade start
//input int    HourEnd   =  20; // Hour of trade end
input string desc1 ="1--------- PullBack  ------------";  
input int Ema1Period=4;   //Fast MA Period
input int Ema2Period=70;  //Secound EMA Period
input int GannBars=3;     //Fast Gann Bars;
input string desc2="2.--------- Accel MA -------------";
input ENUM_TIMEFRAMES MA_TF=PERIOD_H1; // Ma TF
input double MA_K=0.45; // Ma K
input int    MA_Period=40;// Ma period  
input int    MA_Smoothing=10;// Ma Smoothing  


//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end
   int               m_pullback_handle;   // GANN Handle
   int               m_pb_ema1_period;     // Ema1 Period
   int               m_pb_ema2_period;     // Ema2 Period
   int               m_pb_gann_bars;     // Gann Bars
   ENUM_TIMEFRAMES   m_ma_tf;  // MA TF
   int               m_ma_handle;  // MA Handle
   double            m_ma_k;  // MA K
   int               m_ma_period;  // MA period
   int               m_ma_smoothing;  // MA Smoothing

public:
   void              CMyEA();
   void             ~CMyEA();
   virtual bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   virtual bool      Main();                              // main function
   virtual void      OpenPosition(long dir);              // open position on signal
   virtual void      ClosePosition(long dir);             // close position on signal
  };
//------------------------------------------------------------------	CMyEA
void CMyEA::CMyEA(void) { }
//------------------------------------------------------------------	~CMyEA
void CMyEA::~CMyEA(void)
  {
   IndicatorRelease(m_pullback_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);  // initialize parent class
                                                       // copy parameters
   m_risk=Risk;
   m_tp=TP;
   m_sl=SL;
//   m_hourStart=HourStart;
//   m_hourEnd=HourEnd;
//---
   m_pb_ema1_period=Ema1Period;
   m_pb_ema2_period=Ema2Period;
   m_pb_gann_bars=GannBars;


   m_ma_tf=MA_TF;
   m_ma_k=MA_K;
   m_ma_period=MA_Period;
   m_ma_smoothing=MA_Smoothing;

//---
   m_ma_handle=iCustom(NULL,m_ma_tf,"Accel_MA_v1_03",m_ma_k,m_ma_period,m_ma_smoothing);
   if(m_ma_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_pullback_handle=iCustom(m_smb,m_tf,"pullback_v1_11",m_pb_ema1_period,m_pb_ema2_period,m_pb_gann_bars);
   if(m_pullback_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit
   
   m_bInit=true; return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   static CIsNewBar NB;
   if(!NB.IsNewBar(m_smb,m_tf))return (true);

// check each direction
   MqlRates rt[2];
   if(CopyRates(m_smb,m_tf,1,2,rt)!=2)
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }

   double SELL[2];
   double BUY[2];
   double MA[3];
   double EMA1[3];
   double EMA2[3];

   if(CopyBuffer(m_ma_handle,1,1,3,MA)!=3)
     { Print("CopyBuffer Ma - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_pullback_handle,0,1,2,SELL) != 2) 
     { Print("CopyBuffer pullback - no data 1"); return(WRONG_VALUE); }
   if(CopyBuffer(m_pullback_handle,1,1,2,BUY) != 2) 
     { Print("CopyBuffer pullback - no data 2"); return(WRONG_VALUE); }

   if(CopyBuffer(m_pullback_handle,2,1,3,EMA1) != 3) 
     { Print("CopyBuffer pullback - no data 2"); return(WRONG_VALUE); }
   if(CopyBuffer(m_pullback_handle,3,1,3,EMA2) != 3) 
     { Print("CopyBuffer pullback - no data 2"); return(WRONG_VALUE); }

   if(EMA1[1]>EMA2[1] )
   {
      // CLOSE SELL
      ClosePosition(ORDER_TYPE_SELL);
      // OPEN BUY
      if(BUY[1]!= EMPTY_VALUE && MA[1]!=1)
         OpenPosition(ORDER_TYPE_BUY);
   }

   if(EMA1[1]<EMA2[1])
   {
      // CLSOE BUY
      ClosePosition(ORDER_TYPE_BUY);

      // OPEN SELL
      if(SELL[1]!=EMPTY_VALUE && MA[1]!=1)
         OpenPosition(ORDER_TYPE_SELL);
   }
   
   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;

//   if(!CheckTime(StringToTime(IntegerToString(m_hourStart)+":00"),
//      StringToTime(IntegerToString(m_hourEnd)+":00"))) return;

   double lot=CountLotByRisk(m_sl,m_risk,0);
   if(lot<=0) return;
   DealOpen(dir,lot,m_sl,m_tp);
  }
//------------------------------------------------------------------	ClosePos
void CMyEA::ClosePosition(long dir)
  {
   if(!PositionSelect(m_smb)) return;
   if(dir!=PositionGetInteger(POSITION_TYPE)) return;
   m_trade.PositionClose(m_smb,1);
  }

CMyEA ea; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ea.Init(Symbol(),Period()); // initialize expert

                               // initialization example
// ea.Init(Symbol(), PERIOD_M5); // for fixed timeframe
// ea.Init("USDJPY", PERIOD_H2); // for fixed symbol and timeframe

   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ea.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+

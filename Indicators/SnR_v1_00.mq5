//+------------------------------------------------------------------+
//|                                                    SnR_v1_00.mq5 |
//| SnR                                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_buffers 21
#property indicator_plots   6
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 2

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrGold
#property indicator_width3 2

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrGold
#property indicator_width4 2

#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrRed
#property indicator_width5 1

#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrDodgerBlue
#property indicator_width6 1
//+------------------------------------------------------------------+
//| CInfo                                                            |
//+------------------------------------------------------------------+
class CInfo
  {
protected:
   int               m_last_top;
   int               m_last_btm;

   int               m_last_k_top;
   int               m_last_k_btm;

   int               m_turn_pos;
   int               m_turn_dir;

   int               m_trend_pos;
   int               m_is_trend;

public:
   void              CInfo(){};                   // constructor
   void             ~CInfo(){};                   // destructor
   void              Init()
     {
      m_last_top=NULL;
      m_last_btm=NULL;
      m_last_k_top=NULL;
      m_last_k_btm=NULL;
      m_turn_pos=NULL;
      m_turn_dir=NULL;
      m_trend_pos=NULL;
      m_is_trend=NULL;
     }
   int LastTop() { return m_last_top;}
   int LastBtm() { return m_last_btm;}
   int LastKTop() { return m_last_k_top;}
   int LastKBtm() { return m_last_k_btm;}
   int TurnPos() { return m_turn_pos;}
   int TurnDir() { return m_turn_dir;}
   int TrendPos() { return m_trend_pos;}
   int IsTrend() { return m_is_trend;}

   void LastTop(int v) {  m_last_top=v;}
   void LastBtm(int v) { m_last_btm=v;}
   void LastKTop(int v) {m_last_k_top=v;}
   void LastKBtm(int v) { m_last_k_btm=v;}
   void SetTurn(int i,int v) { m_turn_pos=i;m_turn_dir=v;}
   void SetTrend(int i,int v) { m_trend_pos=i;m_is_trend=v;}

  };
//+------------------------------------------------------------------+
//| CBuffer                                                          |
//+------------------------------------------------------------------+
class CBuffer
  {
protected:
   int               m_size;
   int               m_index[];
   double            m_data[];
   int               m_last_pos;
public:
   void              CBuffer(){};                   // constructor
   void             ~CBuffer(){};                   // destructor
   void              Init(const int sz)
     {
      m_size=sz;
      m_last_pos=0;
      ArrayResize(m_index,m_size);
      ArrayResize(m_data,m_size);
      ArrayFill(m_index,0,m_size,NULL);
      ArrayFill(m_data,0,m_size,NULL);
     }
   int Size() { return m_size;}
   double GetValue(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_data [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   int GetIndex(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_index [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   void Add(const int index,const double value)
     {
      m_data[m_last_pos]=value;
      m_index[m_last_pos]=index;
      m_last_pos=(m_last_pos+1)%m_size;
     }
  };

//+------------------------------------------------------------------+

//--- input parameters

input int Inp1stEmaPeriod=25;  //1st EMA Period
input int Inp2ndEmaPeriod=55;  //2nd EMA Period
input int Inp3rdEmaPeriod=120; //3rd EMA Period
input int Inp1stMacdSig = 18;  //1st Signal Period;
input int Inp2ndMacdSig=30;    //2nd Signal Period;
input int InpSmoothing=5;      //Smoothing Price
input int InpChannelPeriod=37; //ChannelPeriod;

double AtrAlpha=0.99;

double Alpha1 = 2.0/(Inp1stEmaPeriod+1.0);
double Alpha2 = 2.0/(Inp2ndEmaPeriod+1.0);
double Alpha3 = 2.0/(Inp3rdEmaPeriod+1.0);

double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;

//---- will be used as indicator buffers
double ZZ[];
double LO[];
double HI[];
double KTOP[];
double KBTM[];
double ATR[];
double PRICE[];
double ZTOP[];
double ZBTM[];
double UPPER[];
double LOWER[];
double TREND[];
double FROM[];

double TOP[];
double BTM[];
double EMA1[];
double EMA2[];
double EMA3[];
double MACD1[];
double MACD2[];
double MACD1SIG[];
double MACD2SIG[];

//---- declaration of global variables

int min_rates_total;
CInfo Info;
CBuffer TopBuffer;
CBuffer BtmBuffer;

CBuffer ZTopBuffer;
CBuffer ZBtmBuffer;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Info.Init();
   ZTopBuffer.Init(100);
   ZBtmBuffer.Init(100);

   TopBuffer.Init(100);
   BtmBuffer.Init(100);
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);

   SetIndexBuffer(i++,KTOP,INDICATOR_DATA);
   SetIndexBuffer(i++,KBTM,INDICATOR_DATA);
   SetIndexBuffer(i++,UPPER,INDICATOR_DATA);
   SetIndexBuffer(i++,LOWER,INDICATOR_DATA);

   SetIndexBuffer(i++,ZTOP,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,ZBTM,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,TREND,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,PRICE,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FROM,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,MACD1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD1SIG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD2SIG,INDICATOR_CALCULATIONS);

   SetIndexBuffer(i++,HI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,LO,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_ARROW,217);
   PlotIndexSetInteger(1,PLOT_ARROW,218);
   PlotIndexSetInteger(2,PLOT_ARROW,140);
   PlotIndexSetInteger(3,PLOT_ARROW,140);
   PlotIndexSetInteger(4,PLOT_ARROW,158);
   PlotIndexSetInteger(5,PLOT_ARROW,158);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-25);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,25);

//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---
   int i,first;
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      ATR[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      HI[i]= ((high[i]+low[i]+close[i])/3  + high[i] + high[i])/3;
      LO[i]= ((high[i]+low[i]+close[i])/3  + low[i]  + low[i] )/3;

      //---
      //---
      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;
      FROM[i]=EMPTY_VALUE;
      TREND[i]=EMPTY_VALUE;
      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      ZTOP[i]=EMPTY_VALUE;
      ZBTM[i]=EMPTY_VALUE;
      KTOP[i]=EMPTY_VALUE;
      KBTM[i]=EMPTY_VALUE;
      TREND[i]=EMPTY_VALUE;
      //---
      EMA1[i]=close[i];
      EMA2[i]=close[i];
      EMA3[i]=close[i];
      //---
      PRICE[i]=close[i];
      if(i==begin_pos)
        {
         // only first time
         continue;
        }

      double atr=fmax(ATR[i-1]*0.667,fmin(ATR[i],ATR[i-1]*1.333));
      ATR[i]=(1-AtrAlpha)*atr+AtrAlpha*ATR[i-1];
      if(i==rates_total-1)
        {
         // new bar
         continue;
        }
      //---
      EMA1[i]=Alpha1*EMA1[i]+(1-Alpha1)*EMA1[i-1];
      EMA2[i]=Alpha2*EMA2[i]+(1-Alpha2)*EMA2[i-1];
      EMA3[i]=Alpha3*EMA3[i]+(1-Alpha3)*EMA3[i-1];
      MACD1[i]=EMA1[i]-EMA2[i];
      MACD2[i]=EMA2[i]-EMA3[i];
      //---
      int i1st=begin_pos+fmax(Inp1stMacdSig,Inp2ndMacdSig)+1;
      if(i<=i1st)continue;

      MACD1SIG[i]=SimpleMA(i,Inp1stMacdSig, MACD1);
      MACD2SIG[i]=SimpleMA(i,Inp2ndMacdSig, MACD2);
      if(i<=i1st+1)continue;
      PRICE[i]=C1*PRICE[i]+C2*PRICE[i-1]+C3*PRICE[i-2];

      //---
      if(MACD1[i]>0 && MACD1[i-1]<0){Info.SetTurn( i, 1);}
      if(MACD1[i]<0 && MACD1[i-1]>0){Info.SetTurn( i, -1);}
      //---
      if(MACD2[i]>0 && MACD2[i-1]<0){Info.SetTrend(i,1);}
      if(MACD2[i]<0 && MACD2[i-1]>0){Info.SetTrend(i,-1);}


      if(Info.TurnPos()==NULL)continue;
      if(Info.TrendPos()==NULL)continue;
      int i2nd=i1st+Inp3rdEmaPeriod+1;
      if(i<=i2nd)continue;

      if(Info.TurnPos()==i)
        {
         if(Info.TurnDir()==1)
           {
            Info.LastTop(i);
           }
         if(Info.TurnDir()==-1)
           {
            Info.LastBtm(i);
           }
        }

      else
        {
         if(Info.TurnDir()==1)
           {
            if(HI[i]>HI[Info.LastTop()]) Info.LastTop(i);

            if(((HI[Info.LastTop()]-EMA1[Info.TrendPos()])>ATR[i]*15)
               && (MACD2[i]>0 && MACD2[i]>MACD2SIG[i])
               && (MACD1[i]<MACD1SIG[i] && MACD1[i-1]>MACD1SIG[i-1])
               )
              {
               TOP[Info.LastTop()]=HI[Info.LastTop()];
               Info.LastKTop(Info.LastTop());
              }
           }

         if(Info.TurnDir()==-1)
           {
            if(LO[i]<LO[Info.LastBtm()]) Info.LastBtm(i);
            if(((EMA1[Info.TrendPos()]-LO[Info.LastBtm()])>ATR[i]*15)
               && (MACD2[i]<0 && MACD2[i]<MACD2SIG[i])
               && (MACD1[i]>MACD1SIG[i] && MACD1[i-1]<MACD1SIG[i-1])
               )
              {

               BTM[Info.LastBtm()]=LO[Info.LastBtm()];
               Info.LastKBtm(Info.LastBtm());
              }

           }
        }
      int ifrom=NULL;
      if((Info.IsTrend()==1 && Info.LastKTop()!=NULL)
         && (MACD2[i]<MACD2SIG[i] && MACD2[i-1]>=MACD2SIG[i-1])
         && (Info.LastKTop()>Info.LastKBtm())
         )
        {
         KTOP[Info.LastKTop()]=HI[Info.LastKTop()];
         ifrom=Info.LastKTop();
        }
      if((Info.IsTrend()==-1 && Info.LastKBtm()!=NULL)
         && (MACD2[i]>MACD2SIG[i] && MACD2[i-1]<=MACD2SIG[i-1])
         && (Info.LastKTop()<Info.LastKBtm())
         )
        {
         KBTM[Info.LastKBtm()]=LO[Info.LastKBtm()];
         ifrom=Info.LastKBtm();
        }
      if(ifrom!=NULL)
        {

         FROM[i]=i;
         TREND[i]=Info.IsTrend();
         if(ifrom<i-InpChannelPeriod) ifrom=i-InpChannelPeriod;
         double dmax=HI[ArrayMaximum(HI,ifrom,i-(ifrom-1))];
         double dmin=LO[ArrayMinimum(LO,ifrom,i-(ifrom-1))];
         UPPER[i]=dmax;
         LOWER[i]=dmin;

         //---
        }

      else
        {
         if(FROM[i-1]!=EMPTY_VALUE)
           {
            ifrom=int(FROM[i-1]);
            if(ifrom<i-InpChannelPeriod) ifrom=i-InpChannelPeriod;
            double ma=(PRICE[i-2]+PRICE[i-3]+PRICE[i-4])/3;
            if(PRICE[i]<UPPER[i-1] && ma>UPPER[i-1])
              {
               double dmax=HI[ArrayMaximum(HI,ifrom,i-(ifrom-1))];
               UPPER[i]=dmax;
               LOWER[i]=LOWER[i-1];
              }
            else if(PRICE[i]>LOWER[i-1] && ma<LOWER[i-1])
              {
               double dmin=LO[ArrayMinimum(LO,ifrom,i-(ifrom-1))];
               LOWER[i]=dmin;
               UPPER[i]=UPPER[i-1];
              }
            else if(FROM[i-1]<i-InpChannelPeriod && PRICE[i]<UPPER[i-1] && PRICE[i]>LOWER[i-1])
              {
               double dmax=HI[ArrayMaximum(HI,ifrom,i-(ifrom-1))];
               double dmin=LO[ArrayMinimum(LO,ifrom,i-(ifrom-1))];
               UPPER[i]=(UPPER[i-1]>dmax)? dmax: UPPER[i-1];
               LOWER[i]=(LOWER[i-1]<dmin)? dmin: LOWER[i-1];
               if((UPPER[i]-LOWER[i])<2*ATR[i])
                 {
                  UPPER[i]=dmax;
                  LOWER[i]=dmin;
                 }
              }
            else
              {
               UPPER[i]=UPPER[i-1];
               LOWER[i]=LOWER[i-1];

              }
            TREND[i]=TREND[i-1];
            FROM[i]=FROM[i-1];
           }
        }

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+

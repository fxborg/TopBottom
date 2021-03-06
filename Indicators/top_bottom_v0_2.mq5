//+------------------------------------------------------------------+
//|                                              top_bottom_v0_2.mq5 |
//| Top & Bottom v0.2                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_buffers 16
#property indicator_plots   5
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 2

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrGold
#property indicator_width3 4

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrGold
#property indicator_width4 4


#property indicator_type5 DRAW_SECTION
#property indicator_color5 clrGainsboro
#property indicator_width5 2

#property indicator_type6 DRAW_LINE
#property indicator_color6 clrDodgerBlue
#property indicator_width6 2

#property indicator_type7 DRAW_SECTION
#property indicator_color7 clrDodgerBlue
#property indicator_width7 2
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

input int InpSmoothing=5;  //1st Smoothing Price

input int Inp1stEmaPeriod=25;  //1st EMA Period
input int Inp2ndEmaPeriod=55; //2nd EMA Period
input int Inp3rdEmaPeriod=120; //3rd EMA Period
input int Inp1stMacdSig = 18;  //1st Signal Period;
input int Inp2ndMacdSig=30; //2nd Signal Period;

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

CBuffer TopBuffer;
CBuffer BtmBuffer;

static int s_last_top=NULL;
static int s_last_btm=NULL;
static int s_last_k_top=NULL;
static int s_last_k_btm=NULL;

static int s_turn_pos=NULL;
static int s_turn_dir=NULL;

static int s_trend_pos=NULL;
static int s_is_trend=NULL;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   SetIndexBuffer(i++,ZZ,INDICATOR_DATA);

   SetIndexBuffer(i++,PRICE,INDICATOR_CALCULATIONS);

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

      HI[i]= (close[i]+high[i-1]+high[i])/3;
      LO[i]= (close[i]+low[i-1]+low[i])/3;

      //---
      ZZ[i]=EMPTY_VALUE;
      //---
      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      KTOP[i]=EMPTY_VALUE;
      KBTM[i]=EMPTY_VALUE;
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

      if(i==rates_total-1)continue;

      ATR[i]=(1-AtrAlpha)*ATR[i]+AtrAlpha*ATR[i-1];

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
/*
      if(PRICE[i]>EMA1[i] && PRICE[i-1]<=EMA1[i-1]){s_turn_pos = i; s_turn_dir= 1;}
      if(PRICE[i]<EMA1[i] && PRICE[i-1]>=EMA1[i-1]){s_turn_pos = i; s_turn_dir= -1;}

*/
      if(MACD1[i]>0 && MACD1[i-1]<0){s_turn_pos = i; s_turn_dir= 1;}
      if(MACD1[i]<0 && MACD1[i-1]>0){s_turn_pos = i; s_turn_dir= -1;}



      if(MACD2[i]>0 && MACD2[i-1]<0){s_trend_pos = i; s_is_trend= 1;}
      if(MACD2[i]<0 && MACD2[i-1]>0){s_trend_pos = i; s_is_trend= -1;}


      if(s_turn_pos==NULL)continue;
      if(s_trend_pos==NULL)continue;
      int i2nd=i1st+Inp3rdEmaPeriod+1;
      if(i<=i2nd)continue;

      if(s_turn_pos==i)
        {
         if(s_turn_dir==1)
           {
            s_last_top=i;
           }
         if(s_turn_dir==-1)
           {
            s_last_btm=i;
           }
        }

      else
        {
         if(s_turn_dir==1)
           {
            if(HI[i]>HI[s_last_top]) s_last_top=i;

            if(((HI[s_last_top]-EMA1[s_trend_pos])>ATR[i]*10)
               && (MACD2[i]>0 && MACD2[i]>MACD2SIG[i])
               && (MACD1[i]<MACD1SIG[i] && MACD1[i-1]>MACD1SIG[i-1]))
              {

               TOP[s_last_top]=HI[s_last_top];
               s_last_k_top=s_last_top;

              }
           }

         if(s_turn_dir==-1)
           {
            if(LO[i]<LO[s_last_btm]) s_last_btm=i;
            if(((EMA1[s_trend_pos]-LO[s_last_btm])>ATR[i]*10)
               && (MACD2[i]<0 && MACD2[i]<MACD2SIG[i])
               && (MACD1[i]>MACD1SIG[i] && MACD1[i-1]<MACD1SIG[i-1]))
              {
               BTM[s_last_btm]=LO[s_last_btm];
               s_last_k_btm=s_last_btm;
              }

           }
        }
      if((s_is_trend==1 && s_last_k_top)
         && (MACD2[i]<MACD2SIG[i] && MACD2[i-1]>=MACD2SIG[i-1]))
        {
         KTOP[s_last_k_top]=HI[s_last_k_top];

        }
      if((s_is_trend==-1 && s_last_k_btm)
         && (MACD2[i]>MACD2SIG[i] && MACD2[i-1]<=MACD2SIG[i-1]))
        {
         KBTM[s_last_k_btm]=LO[s_last_k_btm];

        }

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+

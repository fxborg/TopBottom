//+------------------------------------------------------------------+
//|                                                    SnR_v1_00.mq5 |
//| SnR                                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 21
#property indicator_plots  3
#property indicator_chart_window

#property indicator_type1 DRAW_COLOR_ARROW
#property indicator_color1 clrDeepPink,clrRed
#property indicator_width1 1

#property indicator_type2 DRAW_COLOR_ARROW
#property indicator_color2 clrAqua,clrDodgerBlue
#property indicator_width2 1

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrGold
#property indicator_width3 2

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrMaroon
#property indicator_width4 1

#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrDodgerBlue
#property indicator_width5 1
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   int               m_signal_b;
   int               m_signal_a;
   int               m_last_side;
   double            m_last_high;
   double            m_last_low;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_signal_a=NULL;
      m_signal_b=NULL;
      m_last_high=NULL;
      m_last_low=NULL;
      m_last_side=NULL;
     }
   int SignalA() { return m_signal_a;}
   void SignalA(int v) {  m_signal_a=v;}
   int SignalB() { return m_signal_b;}
   void SignalB(int v) {  m_signal_b=v;}
   int LastSide() { return m_last_side;}
   void LastSide(int v) {  m_last_side=v;}

   double LastHigh() { return m_last_high;}
   void LastHigh(double v) {  m_last_high=v;}
   double LastLow() { return m_last_low;}
   void LastLow(double v) {  m_last_low=v;}

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

input int InpEmaPeriod=20;  //1st EMA Period
input int InpCalcBars=10;  //Calc Bars
input int InpGannBars=1; //Gann Bars;

double AtrAlpha=0.95;

double EmaAlpha=2.0/(InpEmaPeriod+1.0);

//---- will be used as indicator buffers
double GANN[];
double BUY[];
double SELL[];
double BUY_TYPE[];
double SELL_TYPE[];

double ATR[];
double LO[];
double HI[];
double EMA[];
double POS[];
double NEG[];
double SUP[];
double RES[];
double POSX[];
double NEGX[];

CStatus Status;
CBuffer TopBuffer;
CBuffer BtmBuffer;

//---- declaration of global variables

int min_rates_total=InpGannBars+InpCalcBars+2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;


   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,SELL_TYPE,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);

   SetIndexBuffer(i++,BUY_TYPE,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,EMA,INDICATOR_DATA);
   SetIndexBuffer(i++,RES,INDICATOR_DATA);
   SetIndexBuffer(i++,SUP,INDICATOR_DATA);

   SetIndexBuffer(i++,HI,INDICATOR_DATA);
   SetIndexBuffer(i++,LO,INDICATOR_DATA);
   SetIndexBuffer(i++,NEG,INDICATOR_DATA);
   SetIndexBuffer(i++,POS,INDICATOR_DATA);

   SetIndexBuffer(i++,POSX,INDICATOR_DATA);
   SetIndexBuffer(i++,NEGX,INDICATOR_DATA);

   SetIndexBuffer(i++,GANN,INDICATOR_DATA);
   SetIndexBuffer(i++,ATR,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW,234);
   PlotIndexSetInteger(1,PLOT_ARROW,233);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);

//---
   Status.Init();
   TopBuffer.Init(100);
   BtmBuffer.Init(100);
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
      GANN[i]=0;
      ATR[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      SELL[i]=EMPTY_VALUE;
      BUY[i]=EMPTY_VALUE;
      POS[i]=EMPTY_VALUE;
      NEG[i]=EMPTY_VALUE;

      POSX[i]=0;
      NEGX[i]=0;
      //---
      HI[i]=EMPTY_VALUE;
      LO[i]=EMPTY_VALUE;
      SUP[i]=EMPTY_VALUE;
      RES[i]=EMPTY_VALUE;
      //---
      
      //---
      EMA[i]=close[i];
      

      if(i==begin_pos)
        {
         // only first time
         continue;
        }

      double gann=GANN[i-1];
      gannswing(gann,high,low,close,i);
      GANN[i]=gann;

      double atr=fmax(ATR[i-1]*0.667,fmin(ATR[i],ATR[i-1]*1.333));
      ATR[i]=(1-AtrAlpha)*atr+AtrAlpha*ATR[i-1];
      //---
      EMA[i]=EmaAlpha*EMA[i]+(1-EmaAlpha)*EMA[i-1];

      double margin=ATR[i]*0.75;



      //---
      int i1st=begin_pos+InpCalcBars+3;
      if(i<=i1st)continue;

      double pos=0;
      double neg=0;
      int dir=0;
      int cnt=0;

      double h3=EMA[i]+ATR[i]*2.5;
      double h2=EMA[i]+ATR[i]*1.;
      double h1=EMA[i]+ATR[i]*0.5;
      double l1=EMA[i]-ATR[i]*0.5;
      double l2=EMA[i]-ATR[i]*1.;
      double l3=EMA[i]-ATR[i]*2.5;

      //---
      if((low[i]>l1 && high[i]>h1 && high[i]<h3))
        {
         POSX[i]=POSX[i-1]+1;
         POS[i]=high[i];
        }
      //---         
      if((high[i]<h1 && low[i]<l1 && low[i]>l3))
        {
         NEGX[i]=NEGX[i-1]+1;
         NEG[i]=low[i];

        }
      //---

      //---
      int i2nd=i1st+InpCalcBars+3;
      if(i<=i2nd)continue;
      double upper=0.;

      for(int j=0;j<InpCalcBars;j++)
        {
         if(POSX[i-j]==0)break;
         if(upper==0. || POS[i-j]>upper)upper=POS[i-j];
         Status.LastSide(1);
        }
      //---
      double lower=0.;
      for(int j=0;j<InpCalcBars;j++)
        {
         if(NEGX[i-j]==0)break;
         if(lower==0. || NEG[i-j]<lower)lower=NEG[i-j];
         Status.LastSide(-1);
        }

      if(POSX[i]>=2 && close[i]>l1)
        {
         if(Status.LastHigh()==NULL || Status.LastHigh()<upper) Status.LastHigh(upper);
         HI[i]=upper;
        }
      if(NEGX[i]>=2 && close[i]<h1)
        {
         if(Status.LastLow()==NULL || Status.LastLow()>lower)Status.LastLow(lower);
         LO[i]=lower;
        }
      //---

      //---
      if(HI[i]==EMPTY_VALUE && HI[i-1]!=EMPTY_VALUE)
        {
         RES[i]=Status.LastHigh();
         Status.SignalA(NULL);
         Status.SignalB(NULL);
         Status.LastHigh(NULL);
        }

      //---
      if(LO[i]==EMPTY_VALUE && LO[i-1]!=EMPTY_VALUE)
        {
         SUP[i]=Status.LastLow();
         Status.SignalA(NULL);
         Status.SignalB(NULL);
         Status.LastLow(NULL);
        }

      if(Status.LastSide()==1 &&RES[i]==EMPTY_VALUE)     RES[i]=RES[i-1];
      if(Status.LastSide()==-1 &&SUP[i]==EMPTY_VALUE)    SUP[i]=SUP[i-1];

      if(Status.LastSide()==1 && close[i]<l1)
      {
       RES[i]=EMPTY_VALUE;
       Status.LastSide(NULL) ;
      }
      if(Status.LastSide()==-1 && close[i]>h1)
      {
       SUP[i]=EMPTY_VALUE;
       Status.LastSide(NULL);
      }
      if(i==rates_total-1)
        {
         continue;
        }

      // EMA Brake
      if(Status.LastSide()==1 && Status.SignalA()==NULL
         && close[i]<EMA[i] && GANN[i]<0) Status.SignalA(-1);
      // Resistance Brake
      if(Status.LastSide()==1 && Status.SignalB()==NULL
         && close[i]>RES[i] && GANN[i]>0) Status.SignalB(1);
      // EMA Brake
      if(Status.LastSide()==-1 && Status.SignalA()==NULL
         && close[i]>EMA[i] && GANN[i]>0) Status.SignalA(1);
      // Support Brake
      if(Status.LastSide()==-1 && Status.SignalB()==NULL
         && close[i]<SUP[i] && GANN[i]<0) Status.SignalB(-1);

      if(i<=i2nd+1)continue;


      // EMA Brake
      if(Status.LastSide()==1 && Status.SignalA()==-1)
        {
         if(GANN[i]<0 && GANN[i-1]>0)Status.SignalA(-2);
        }
      // Resistance Brake
      if(Status.LastSide()==1 && Status.SignalB()==1)
        {
         if(GANN[i]>0 && GANN[i-1]<0) Status.SignalB(2);
        }
      // EMA Brake
      if(Status.LastSide()==-1 && Status.SignalA()==1)
        {
         if(GANN[i]>0 && GANN[i-1]<0) Status.SignalA(2);
        }
      // Support Brake
      if(Status.LastSide()==-1 && Status.SignalB()==-1)
        {
         if(GANN[i]<0 && GANN[i-1]>0)Status.SignalB(-2);
        }

      // EMA Brake
      if(Status.LastSide()==1 && Status.SignalA()==-2)
        {
         if(high[i]<high[i-1] && high[i-1]<RES[i-1])
           {
            Status.SignalA(-3);
            SELL[i]=high[i];
            SELL_TYPE[i]=0;
            if(close[i]<EMA[i])Status.LastSide(NULL);
           }
        }

      // Resistance Brake
      if(Status.LastSide()==1 && Status.SignalB()==2)
        {
         if(low[i]>low[i-1] && low[i-1]>EMA[i-1])
           {
            Status.SignalB(3);
            BUY[i]=low[i];
            BUY_TYPE[i]=1;

            if(close[i]>RES[i])Status.LastSide(NULL);
           }
        }
      // EMA Brake
      if(Status.LastSide()==-1 && Status.SignalA()==2)
        {

         if(low[i]>low[i-1] && low[i-1]>SUP[i-1])
           {
            Status.SignalA(3);
            BUY[i]=low[i];
            BUY_TYPE[i]=0;
            if(close[i]>EMA[i])Status.LastSide(NULL);
           }
        }
      // Support Brake
      if(Status.LastSide()==-1 && Status.SignalB()==-2)
        {
         if(high[i]<high[i-1] && high[i-1]<EMA[i-1])
           {
            Status.SignalB(-3);
            SELL[i]=high[i];
            SELL_TYPE[i]=1;
            if(close[i]<SUP[i])Status.LastSide(NULL);
           }
        }

      //---

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void gannswing(double  &trend,const double  &h[],const double  &l[],const double  &c[],const int i)
  {
// inside bar
   if(h[i-1]>=h[i] && l[i-1] <= l[i]) return;

   bool isOutSide  = (h[i-1] <  h[i]   && l[i-1] >  l[i]);
   bool prevInSide = (h[i-2] >= h[i-1] && l[i-2] <= l[i-1]);
   bool isUpClose  = h[i-1] < c[i];
   bool isDnClose  = l[i-1] > c[i];
   bool isHigh     = h[i-1] < h[i];
   bool isLow      = l[i-1] > l[i];


// first time only
   if(trend==0.0)trend=1.0;

   if(trend>0.0) // Up Trend 
     {
      double dmin=l[ArrayMinimum(l,i-InpGannBars,InpGannBars)];
      if((isOutSide && dmin>c[i]) || (!isOutSide && dmin>l[i]))
        {
         trend=-InpGannBars;
         return;
        }
      // up or not enough down...
      else if(trend>1.0)
        {
         if((isOutSide && isUpClose) || (!isOutSide && isLow))
           {
            trend--;
            return;
           }
        }
      // enough down
      else if(trend==1.0)
        {
         if((isOutSide && prevInSide) || (!isOutSide && isLow))
           {
            trend=-InpGannBars;
            return;
           }
        }
     }
   else if(trend<0.0) // Down Trend
     {
      double dmax=h[ArrayMaximum(h,i-InpGannBars,InpGannBars)];
      if((isOutSide && dmax<c[i]) || (!isOutSide && dmax<h[i]))
        {
         trend=InpGannBars;
         return;
        }
      // down or not enough up
      if(trend<-1.0)
        {
         if((isOutSide && isDnClose) || (!isOutSide && isHigh))
           {
            trend++;
            return;
           }
        }
      // dnough up
      else if(trend==-1.0)
        {
         if((isOutSide && prevInSide) || (!isOutSide && isHigh))
           {
            trend=InpGannBars;
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+

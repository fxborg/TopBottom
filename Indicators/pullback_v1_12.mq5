//+------------------------------------------------------------------+
//|                                               pullback_v1_11.mq5 |
//| pullback 1.11                             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"

#property indicator_buffers 12
#property indicator_plots  2
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 2

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrRed
#property indicator_width3 2

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrGold
#property indicator_width4 2


#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrDeepPink
#property indicator_width5 1

#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrAqua
#property indicator_width6 1

#property indicator_type7 DRAW_ARROW
#property indicator_color7 clrDeepPink
#property indicator_width7 1

#property indicator_type8 DRAW_ARROW
#property indicator_color8 clrAqua
#property indicator_width8 1
#property indicator_type9 DRAW_ARROW
#property indicator_color9 clrDeepPink
#property indicator_width9 1

#property indicator_type10 DRAW_ARROW
#property indicator_color10 clrAqua
#property indicator_width10 1
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   int               m_index;
   int               m_turn;
   int               m_turn_pos;
   int               m_gann_number;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_turn=NULL;
      m_turn_pos=NULL;
      m_gann_number=NULL;
      m_index=NULL;
     }
   int Turn() { return m_turn;}
   void SetTurn(int p,int v) {m_turn_pos=p;  m_turn=v; m_gann_number=0;}
   int TurnPos() { return m_turn_pos;}

   int GannNumber() { return m_gann_number;}
   void CountUp(const int index)
     {

      if(m_index==index)return;
      m_gann_number++;
      m_index=index;
     }
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
      int pos=(m_size+(m_last_pos-1))%m_size;

      if(m_index[pos]==index)
        {
         m_data[pos]=value;
        }
      else
        {
         m_data[m_last_pos]=value;
         m_index[m_last_pos]=index;
         m_last_pos=(m_last_pos+1)%m_size;
        }
     }
  };

//+------------------------------------------------------------------+

//--- input parameters

input int InpSmoothing=3;  //Fast EMA Period
input int InpEma2Period=20;  //Secound EMA Period
input int InpGannBars1=2;    //Fast Gann Bars;

//double Ema1Alpha=2.0/(InpEma1Period+1.0);
double Ema2Alpha=2.0/(InpEma2Period+1.0);

//---- will be used as indicator buffers
double EMA1[];
double EMA2[];

double GANN1[];
double GANN2[];
double BUY[];
double SELL[];

double SIG1T[];
double SIG2T[];
double SIG3T[];
double SIG1B[];
double SIG2B[];
double SIG3B[];

CStatus Status;
CBuffer GannBuffer;

//---- declaration of global variables

int min_rates_total=InpGannBars1+2;

// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double C2 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);
  
   SetIndexBuffer(i++,EMA1,INDICATOR_DATA);
   SetIndexBuffer(i++,EMA2,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG1T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG1B,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG2T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG2B,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG3T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG3B,INDICATOR_DATA);
   SetIndexBuffer(i++,GANN1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,GANN2,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_ARROW,234);
   PlotIndexSetInteger(1,PLOT_ARROW,233);
   PlotIndexSetInteger(4,PLOT_ARROW,140);
   PlotIndexSetInteger(5,PLOT_ARROW,140);
   PlotIndexSetInteger(6,PLOT_ARROW,141);
   PlotIndexSetInteger(7,PLOT_ARROW,141);
   PlotIndexSetInteger(8,PLOT_ARROW,142);
   PlotIndexSetInteger(9,PLOT_ARROW,142);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-25);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,25);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(8,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(9,PLOT_ARROW_SHIFT,10);

//---
   Status.Init();
   GannBuffer.Init(100);
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
      GANN1[i]=0;
      GANN2[i]=0;
      EMA1[i]=close[i];
      EMA2[i]=close[i];
      BUY[i]=EMPTY_VALUE;
      SELL[i]=EMPTY_VALUE;
      SIG1T[i]=EMPTY_VALUE;
      SIG2T[i]=EMPTY_VALUE;
      SIG3T[i]=EMPTY_VALUE;
      SIG1B[i]=EMPTY_VALUE;
      SIG2B[i]=EMPTY_VALUE;
      SIG3B[i]=EMPTY_VALUE;
      if(i<=begin_pos+2)
        {
         // only first time
         continue;
        }
      //EMA1[i]=Ema1Alpha*EMA1[i]+(1-Ema1Alpha)*EMA1[i-1];

      EMA1[i]= C1*EMA1[i]+C2*EMA1[i-1]+C3*EMA1[i-2];

      EMA2[i]=Ema2Alpha*EMA2[i]+(1-Ema2Alpha)*EMA2[i-1];


      //---
      double gann1=GANN1[i-1];
      gannswing(gann1,high,low,close,i,InpGannBars1);
      GANN1[i]=gann1;

      int i1st=begin_pos+5;
      if(i<=i1st)continue;

      if(i<rates_total-1)
        {
         if(EMA1[i]>EMA2[i] && EMA1[i-1]<EMA2[i-1])Status.SetTurn(i,1);
         else if(EMA1[i]<EMA2[i] && EMA1[i-1]>EMA2[i-1])Status.SetTurn(i,-1);
        }
      //---
      if(Status.TurnPos()==NULL) continue;

      //---
      if(i<rates_total-1)
        {
         if(GANN1[i]>0 && GANN1[i-1]<0)
           {
            if(Status.GannNumber()==0)
              {
               if(Status.Turn()==-1)
                 {
                  GannBuffer.Add(i,1);
                  Status.CountUp(i);

                 }
              }
            else
              {
               GannBuffer.Add(i,1);
               Status.CountUp(i);
              }
           }
         //---
         if(GANN1[i]<0 && GANN1[i-1]>0)
           {
            if(Status.GannNumber()==0)
              {
               if(Status.Turn()==1)
                 {
                  GannBuffer.Add(i,-1);
                  Status.CountUp(i);

                 }
              }
            else
              {
               GannBuffer.Add(i,-1);
               Status.CountUp(i);
              }
           }
        }

      if(GannBuffer.GetIndex(0)==i)
        {

         if(Status.GannNumber()==1)
           {

            if(GannBuffer.GetValue(0)==1)
               SIG1B[i]=low[i-1];
            else
               SIG1T[i]=high[i-1];
           }
         if(Status.GannNumber()==2)
           {
            if(GannBuffer.GetValue(0)==1)
              {
               SIG2B[i]=low[i-1];
               BUY[i]=low[i-1];
              }
            else
              {
               SIG2T[i]=high[i-1];
               SELL[i]=high[i-1];
              }
           }
         if(Status.GannNumber()==3)
           {
            if(GannBuffer.GetValue(0)==1)
               SIG3B[i]=low[i-1];
            else
               SIG3T[i]=high[i-1];
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
void gannswing(double  &trend,const double  &h[],const double  &l[],const double  &c[],const int i,const int span)
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
      double dmin=l[ArrayMinimum(l,i-span,span)];
      if((isOutSide && dmin>c[i]) || (!isOutSide && dmin>l[i]))
        {
         trend=-span;
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
            trend=-span;
            return;
           }
        }
     }
   else if(trend<0.0) // Down Trend
     {
      double dmax=h[ArrayMaximum(h,i-span,span)];
      if((isOutSide && dmax<c[i]) || (!isOutSide && dmax<h[i]))
        {
         trend=span;
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
            trend=span;
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+

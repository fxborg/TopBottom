//+------------------------------------------------------------------+
//|                                                 top_btm_v0_1.mq5 |
//| Top & Bottom v0.1                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 20
#property indicator_plots   2
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 2

#property indicator_type3 DRAW_SECTION
#property indicator_color3 clrWhite
#property indicator_width3 2

#property indicator_type4 DRAW_SECTION
#property indicator_color4 clrWhite
#property indicator_width4 2
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
input int InpSlowMaPeriod=120; //Slow MA Period
input int InpFastMaPeriod=50;  //Fast MA Period
input int InpSigPeriod=30;     //Sig MA Period

input int InpLookBack=50;  //Look Back Period

input double InpK=0.5; // K  
input int InpPeriod=5; // Period
input int InpSmoothing=5; //  Smoothing
double  InpThreshhold=0.03; // Threshhold
int AccelPeriod=int(InpK*15);
double alpha=MathMax(0.001,MathMin(1,InpK));

double AtrAlpha=0.99;
double SlowAlpha = 2.0/(InpSlowMaPeriod+1.0);
double FastAlpha = 2.0/(InpFastMaPeriod+1.0);



//---- will be used as indicator buffers
double ATR[];
double TOP[];
double BTM[];
double FAST_EMA[];
double SLOW_EMA[];
double MACD[];

double MA_H[];
double MA_H_[];
double MA_L[];
double MA_L_[];
double MOM_H[];
double VOLAT_H[];
double MOM_L[];
double VOLAT_L[];
double Accel[];
double SIG[];

//---- declaration of global variables
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;
int min_rates_total;

CBuffer TopBuffer;
CBuffer BtmBuffer;

CBuffer TurnBuffer;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   TopBuffer.Init(100);
   BtmBuffer.Init(100);
   TurnBuffer.Init(10);
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);
   SetIndexBuffer(i++,MA_H_,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MOM_H,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,VOLAT_H,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MA_L_,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MOM_L,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,VOLAT_L,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MA_H,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MA_L,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SLOW_EMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,FAST_EMA,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_ARROW,217);
   PlotIndexSetInteger(1,PLOT_ARROW,218);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);

//---
   ArrayResize(Accel,AccelPeriod);
   for(int j=0;j<AccelPeriod;j++) Accel[j]=pow(alpha,MathLog(j+1));
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
      double tr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      FAST_EMA[i]=close[i];
      SLOW_EMA[i]=close[i];

      ATR[i]=tr;
      MA_H[i]=high[i];
      MA_H_[i]=high[i];
      MOM_H[i]=high[i]-high[i-1];
      VOLAT_H[i]=fabs(high[i]-high[i-1]);

      MA_L[i]=low[i];
      MA_L_[i]=low[i];
      MOM_L[i]=low[i]-low[i-1];
      VOLAT_L[i]=fabs(low[i]-low[i-1]);

      if(i==begin_pos)continue;
      FAST_EMA[i]=FastAlpha*FAST_EMA[i]+(1-FastAlpha)*FAST_EMA[i-1];
      SLOW_EMA[i]=SlowAlpha*SLOW_EMA[i]+(1-SlowAlpha)*SLOW_EMA[i-1];
      MACD[i]=FAST_EMA[i]-SLOW_EMA[i];
      if(MACD[i]>0 && MACD[i-1]<=0) TurnBuffer.Add(i,1.0);
      if(MACD[i]<0 && MACD[i-1]>=0) TurnBuffer.Add(i,-1.0);

      ATR[i]=(1-AtrAlpha)*tr+AtrAlpha*ATR[i-1];

      int i1st=begin_pos+1+MathMax(AccelPeriod,InpPeriod);
      if(i<=i1st)continue;
      accelma(MA_H,MA_H_,MOM_H,VOLAT_H,i);
      accelma(MA_L,MA_L_,MOM_L,VOLAT_L,i);

      if(i<=i1st+4)continue;
      if(TOP[i-3]==EMPTY_VALUE && MA_H[i-4]<MA_H[i-2] && MA_H[i-2]>MA_H[i])
        {
         if(TopBuffer.GetIndex(0)==NULL || TopBuffer.GetIndex(0)<i-3) TopBuffer.Add(i-2,MA_H[i-2]);
        }

      if(BTM[i-3]==EMPTY_VALUE && MA_L[i-4]>MA_L[i-2] && MA_L[i-2]<MA_L[i])
        {
         if(BtmBuffer.GetIndex(0)==NULL || BtmBuffer.GetIndex(0)<i-3)BtmBuffer.Add(i-2,MA_L[i-2]);
        }
      int i2nd=i1st+1+InpSlowMaPeriod+InpSigPeriod;
      if(i<=i2nd)continue;

      double trend=0;
      if(SLOW_EMA[i]>SLOW_EMA[i-1] && MACD[i]>0.0)trend=1;
      if(SLOW_EMA[i]<SLOW_EMA[i-1] && MACD[i]<0.0) trend=-1;

      double prev=MACD[i-InpSigPeriod];

      if(TopBuffer.GetIndex(0)==NULL)continue;
      if(BtmBuffer.GetIndex(0)==NULL)continue;

      if(trend>0)
        {
         if(TurnBuffer.GetValue(0)!=1.0)continue;
         if(MACD[i]<prev)
           {
            if(BtmBuffer.GetIndex(0)>TopBuffer.GetIndex(0))continue;

            int from=TurnBuffer.GetIndex(0);

            int imax=ArrayMaximum(MA_H,i-InpLookBack,InpLookBack);

            int to=TopBuffer.GetIndex(0);
            double lowest=MA_L[ArrayMinimum(MA_L,imax,i-to)];

            double net=MA_H[imax]-MA_L[from];
            if(net<(MA_H[imax]-lowest)*2)continue;

            for(int pos=0;pos<TopBuffer.Size();pos++)
              {
               if(TopBuffer.GetIndex(pos)==NULL)break;

               if(TopBuffer.GetIndex(pos)<i-InpLookBack)break;
               if(MACD[BtmBuffer.GetIndex(pos)]<0)break;

               if(TopBuffer.GetValue(pos)<lowest)break;
               TOP[TopBuffer.GetIndex(pos)]=TopBuffer.GetValue(pos);
              }
           }
        }
      if(trend<0)
        {
         if(TurnBuffer.GetValue(0)!=-1.0)continue;

         if(MACD[i]>prev)
           {
            if(BtmBuffer.GetIndex(0)<TopBuffer.GetIndex(0))continue;
            int from=TurnBuffer.GetIndex(0);

            int imin=ArrayMinimum(MA_L,i-InpFastMaPeriod,InpFastMaPeriod);

            int to=BtmBuffer.GetIndex(0);
            double highest=MA_H[ArrayMaximum(MA_H,imin,i-to)];

            double net=MA_H[from]-MA_L[imin];

            if(net<(highest-MA_L[imin])*2)continue;

            for(int pos=0;pos<BtmBuffer.Size();pos++)
              {
               if(BtmBuffer.GetIndex(pos)==NULL)break;
               if(BtmBuffer.GetIndex(pos)<i-InpLookBack)break;
               if(MACD[BtmBuffer.GetIndex(pos)]>0)break;
               if(BtmBuffer.GetValue(pos)>highest)break;
               BTM[BtmBuffer.GetIndex(pos)]=BtmBuffer.GetValue(pos);
              }

           }
        }

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
void accelma(double &main[],double &ma[],const double &mom[],const double &volat[],const int i)
  {
   double dsum=0.0000000001;
   double vol=0.0000000001;
   double b=0;
   double dmax=0;
   double dmin=0;
   for(int j=0;j<AccelPeriod;j++)
     {
      dsum+=mom[i-j]*Accel[j];
      if(dsum>dmax)dmax=dsum;
      if(dsum<dmin)dmin=dsum;
     }
   for(int j=0;j<InpPeriod;j++)
     {
      vol+=volat[i-j];
     }
   double range=MathMax(0.0000000001,dmax-dmin);
   double fact=(vol/range);
   double a=2.0/(fact+1.0);
   double accel=range/vol;
   ma[i]=accel*(ma[i]-ma[i-1])+ma[i-1];
//---
   main[i]=C1*ma[i]+C2*main[i-1]+C3*main[i-2];

  }
//+------------------------------------------------------------------+

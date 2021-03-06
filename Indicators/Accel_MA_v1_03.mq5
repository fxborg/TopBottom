//+------------------------------------------------------------------+
//|                                               Accel_MA_v1_02.mq5 |
//| Accelarated Moving Average v1.03          Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.03"

#property indicator_buffers 9
#property indicator_plots   1
#property indicator_chart_window
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 clrDodgerBlue,clrWhiteSmoke,clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrDodgerBlue
#property indicator_width2 2

//--- input parameters
input double InpK=0.4; // K  
input int InpPeriod=20; // Period
input int InpSmoothing=14; //  Smoothing


double  InpThreshhold=0.04; // Threshhold
int AccelPeriod= int(InpK*20); 
double alpha=MathMax(0.001,MathMin(1,InpK));

double AtrAlpha = 0.99;



//---- will be used as indicator buffers
double ATR[];
double MAIN[];
double MA1[];
double SIG[];
double MOM[];
double VOLAT[];
double Accel[];

//---- declaration of global variables
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpSmoothing );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpSmoothing );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers mapping
//--- indicator buffers
   SetIndexBuffer(0,MAIN,INDICATOR_DATA);
   SetIndexBuffer(1,SIG,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,MA1,INDICATOR_DATA);
   SetIndexBuffer(3,MOM,INDICATOR_DATA);
   SetIndexBuffer(4,VOLAT,INDICATOR_DATA);
   SetIndexBuffer(5,ATR,INDICATOR_DATA);
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
      ATR[i]=tr;
      SIG[i]=1;
      MA1[i]=close[i];
      MAIN[i]=close[i];
      MOM[i]=close[i]-close[i-1];
      VOLAT[i]=fabs(close[i]-close[i-1]);

      if(i==begin_pos)continue;
      double atr=fmax(ATR[i-1]*0.667,fmin(ATR[i],ATR[i-1]*1.333));
      ATR[i]=(1-AtrAlpha)*atr+AtrAlpha*ATR[i-1];

      int i1st=begin_pos+MathMax(AccelPeriod,InpPeriod);
      if(i<=i1st)continue;      
      double dsum=0.0000000001;
      double volat=0.0000000001;
      double b=0;
      double dmax=0;
      double dmin=0;
      for(int j=0;j<AccelPeriod;j++)
        {
         dsum+=MOM[i-j]*Accel[j];
         if(dsum>dmax)dmax=dsum;
         if(dsum<dmin)dmin=dsum;
        }
      for(int j=0;j<InpPeriod;j++)
        {
         volat+=VOLAT[i-j];
        }
       double range=MathMax(0.0000000001,dmax-dmin);
       double fact= (volat/range);
       double a=2.0/(fact+1.0);
       double accel=range/volat;
       MA1[i] =  accel*(close[i]-MA1[i-1])+MA1[i-1];
       //---
       MAIN[i]= C1*MA1[i]+C2*MAIN[i-1]+C3*MAIN[i-2];
       //---
       if(i<=i1st+2)continue;      

       double thr=ATR[i]*InpThreshhold;
       
       
       //---
       double prev =(MAIN[i-3]+MAIN[i-2]+MAIN[i-1])/3;
       double slope = (MAIN[i]-prev) * 0.5;
       
       bool flat = fabs(slope)<thr; 
       
       if(flat)SIG[i]=1;
       else if(slope>0)SIG[i]=0;      
       else if (slope<0)SIG[i]=2;
       else SIG[i]=SIG[i-1];

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+

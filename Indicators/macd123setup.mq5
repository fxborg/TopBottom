//+------------------------------------------------------------------+
//|                                                 macd123setup.mq5 |
//| macd123setup                              Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_buffers 19
#property indicator_plots   9
#property indicator_chart_window
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 1

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 1

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrRed
#property indicator_width3 1

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrDodgerBlue
#property indicator_width4 1

#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrRed
#property indicator_width5 1

#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrDodgerBlue
#property indicator_width6 1

#property indicator_type7 DRAW_LINE
#property indicator_color7 clrRed
#property indicator_width7 2

#property indicator_type8 DRAW_LINE
#property indicator_color8 clrDodgerBlue
#property indicator_width8 2


//+------------------------------------------------------------------+
//| CSignal                                                          |
//+------------------------------------------------------------------+
class CSignal
  {
protected:
   int               m_sig,m_brake_pos,m_prev_pos,m_1st_pos,m_2nd_pos,m_3rd_pos,m_min_pos,m_max_pos;
   double            m_min,m_max;

public:
   void              CSignal(){};                   // constructor
   void             ~CSignal(){};                   // destructor
   void              Init()
     {
      m_sig=0; m_brake_pos=NULL;m_prev_pos=2; m_1st_pos=NULL;  m_2nd_pos=NULL;  m_3rd_pos=NULL;
      m_min_pos=NULL;  m_max_pos=NULL; m_min=NULL; m_max=NULL;
     }
   void              Begin(int a,int b, int sig){ Init(); m_1st_pos=a; m_brake_pos=b; m_sig=sig;}
   void              Exit()                     { int a=m_brake_pos;Init(); m_prev_pos = a;}
   int               Sig()                      { return m_sig;}
   int               GetBrakePos()              { return m_brake_pos;}
   int               Get1stPos()                { return m_1st_pos;}
   int               Get2ndPos()                { return m_2nd_pos;}
   int               Get3rdPos()                { return m_3rd_pos;}
   void              UpdateMax(int i,double v)  { if(m_max==NULL || v>m_max){m_max=v; m_max_pos=i;}}
   int               GetMaxPos()                { return m_max_pos;}
   void              UpdateMin(int i,double v)  { if(m_min==NULL || v<m_min){m_min=v; m_min_pos=i;}}
   int               GetMinPos()                { return m_min_pos;}
   int               GetPrevPos()               { return m_prev_pos;}

   void              SetNextPos(int i)
     {
      if(State()==1)m_2nd_pos=i;
      else if(State()==2)m_3rd_pos=i;
      m_min_pos=NULL; m_min=NULL;m_max_pos=NULL;m_max=NULL;
     }

   int               State()
     {
      if(m_3rd_pos!=NULL) return 3;
      else if(m_2nd_pos!=NULL)return 2;
      else if(m_brake_pos!=NULL)return 1;
      else return 0;
     }
   int               NextDir()
     {
      // (sig=1)->l-h-l ,(sig= -1)->h-l-h
      if(m_sig==0) return 0;
      int dir = (( 1 & State()) == 1) ? 1  : -1;
      return  (dir * m_sig);
     }

   int              ChkNextPos(const double &h[],const double &l[],const double &c[],const int i,const double atr)
     {
      int dir=NextDir();
      if(dir==0)return 0;
      if(dir>0)
        {
         UpdateMax(i,h[i]);
         if((m_max_pos==i-1 && l[i-1]<l[i-2]) || (m_max_pos<i && l[i]<l[i-1]))
           {
            int x=m_max_pos;
            SetNextPos(m_max_pos);
            return x;
           }
        }
      else
        {
         UpdateMin(i,l[i]);
         if((m_min_pos==i-1 && h[i-1]>h[i-2]) || (m_min_pos<i && h[i]>h[i-1]))
           {
            int x=m_min_pos;
            SetNextPos(m_min_pos);
            return x;
           }
        }
      return 0;
     }

  };
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   int               m_last_top;
   int               m_last_btm;

   int               m_last_k_top;
   int               m_last_k_btm;
   int               m_last_macd;
   int               m_turn_pos;
   int               m_turn_dir;

   datetime          m_old_time;
public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_last_macd=NULL;
      m_last_top=NULL;
      m_last_btm=NULL;
      m_turn_pos=NULL;
      m_turn_dir=NULL;
      m_old_time=0;
     }

   int              LastTop() { return m_last_top; }
   int              LastBtm() { return m_last_btm; }

   int              TurnPos() { return m_turn_pos; }
   int              TurnDir() { return m_turn_dir; }
   void             LastMACD(int v) { m_last_macd=v; }
   double           LastMACD() {return m_last_macd; }

   void             LastTop(int v) { m_last_top=v; }
   void             LastBtm(int v) { m_last_btm=v; }
   void             SetTurn(int i,int v) { m_turn_pos=i;m_turn_dir=v;}
   //---
   bool IsNewBar()
     {
      //---
      bool res=false;            // variable for the analysis result
      datetime new_time[1];      // time of a new bar
      //---
      int copied=CopyTime(_Symbol,PERIOD_CURRENT,0,1,new_time); // copy the last bar time into the new_time cell
      //---
      if(copied>0) //  Data have been copied
        {
         if(m_old_time!=new_time[0]) // if the old time of the bar is not equal to new one
           {
            res=true;
            m_old_time=new_time[0];     // store the bar's time
           }
        }
      //---
      return(res);
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
      m_data[m_last_pos]=value;
      m_index[m_last_pos]=index;
      m_last_pos=(m_last_pos+1)%m_size;
     }

  };

//+------------------------------------------------------------------+

//--- input parameters

input int Inp1stMacdSig = 15;  //1st Signal Period;
input int Inp1stEmaPeriod=20;  //1st EMA Period
input int Inp2ndEmaPeriod=43;  //2nd EMA Period
input int  InpKeepPeriod=30;    //Look Back Period 
input double  InpMacdFlatLv=0.5;    //Macd Flat Level 
input double  InpThreshold=1.5;       // S&R Threshold
input bool InpUsingReversal=false;     // Using Reversal 

input int AtrPeriod=200;      // ATR Period

double AtrAlpha=2.0/(AtrPeriod+1.0);

double Alpha1 = 2.0/(Inp1stEmaPeriod+1.0);
double Alpha2 = 2.0/(Inp2ndEmaPeriod+1.0);

//---- will be used as indicator buffers

double ATR[];
double SELL[];
double BUY[];

double EMA1[];
double EMA2[];
double MACD1[];
double MACD1SIG[];
double DN1[];
double UP1[];
double DN2[];
double UP2[];
double DN3[];
double UP3[];
double UPPER[];
double LOWER[];
double HSTEP[];
double LSTEP[];
double BAR[];
double CNT[];
double MEAN[];
double VAR[];
double MACD_DEV[];
//---- declaration of global variables

int min_rates_total;
CStatus Stat;
CBuffer TopBuffer;
CBuffer BtmBuffer;
CSignal UpSignal;
CSignal DnSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Stat.Init();
   UpSignal.Init();
   DnSignal.Init();

   TopBuffer.Init(100);
   BtmBuffer.Init(100);

//---- Initialization of variables of data calculation starting point
   min_rates_total=2;

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);
   SetIndexBuffer(i++,DN1,INDICATOR_DATA);
   SetIndexBuffer(i++,UP1,INDICATOR_DATA);
   SetIndexBuffer(i++,DN2,INDICATOR_DATA);
   
   SetIndexBuffer(i++,UP2,INDICATOR_DATA);
   SetIndexBuffer(i++,UPPER,INDICATOR_DATA);
   SetIndexBuffer(i++,LOWER,INDICATOR_DATA);
   SetIndexBuffer(i++,ATR,INDICATOR_DATA);
   SetIndexBuffer(i++,HSTEP,INDICATOR_DATA);
   
   SetIndexBuffer(i++,LSTEP,INDICATOR_DATA);
   SetIndexBuffer(i++,CNT,INDICATOR_DATA);
   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD1,INDICATOR_CALCULATIONS);
   
   SetIndexBuffer(i++,MACD1SIG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,BAR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MACD_DEV,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,VAR,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_ARROW,242);
   PlotIndexSetInteger(1,PLOT_ARROW,241);
   PlotIndexSetInteger(2,PLOT_ARROW,140);
   PlotIndexSetInteger(3,PLOT_ARROW,140);
   PlotIndexSetInteger(4,PLOT_ARROW,141);
   PlotIndexSetInteger(5,PLOT_ARROW,141);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-20);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,20);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,-10);

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
   int first;
   if(rates_total<=min_rates_total)
      return(0);
//---
   if(!Stat.IsNewBar()) return rates_total;
//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first<prev_calculated) first=prev_calculated-1;

//---
   for(int bar=first;bar<rates_total && !IsStopped(); bar++)
     {

      int i=bar-1;
      BAR[i]=i;
      if(CNT[i]==1)continue;
      CNT[i]=1;

      UPPER[bar]=EMPTY_VALUE;
      LOWER[bar]=EMPTY_VALUE;
      HSTEP[bar]=EMPTY_VALUE;
      LSTEP[bar]=EMPTY_VALUE;
      SELL[bar]=EMPTY_VALUE;
      BUY[bar]=EMPTY_VALUE;
      UP1[bar]=EMPTY_VALUE;
      DN1[bar]=EMPTY_VALUE;
      UP2[bar]=EMPTY_VALUE;
      DN2[bar]=EMPTY_VALUE;
      //---
      if(i==begin_pos)
        {
         ATR[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         EMA1[i]=close[i];
         EMA2[i]=close[i];
        }
      else
        {
         double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
         ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];
         //---
         EMA1[i]=Alpha1*close[i]+(1-Alpha1)*EMA1[i-1];
         EMA2[i]=Alpha2*close[i]+(1-Alpha2)*EMA2[i-1];
        }

      //---
      MACD1[i]=EMA1[i]-EMA2[i];
      if(i==begin_pos)
        {
         VAR[i]=pow(MACD1[i],2);
        }
      else
        {
         VAR[i]=AtrAlpha*pow((MACD1[i]),2)+(1-AtrAlpha)*VAR[i-1];
        }
      double stddev=sqrt(VAR[i])*InpMacdFlatLv;
      MACD_DEV[i]=stddev;

      //---
      int i1st=begin_pos+Inp1stMacdSig+1;
      if(i<=i1st)continue;

      MACD1SIG[i]=SimpleMA(i,Inp1stMacdSig,MACD1); // fast
      if(i<=i1st+1)continue;

      //--- fast macd
      if(MACD1[i]>0 && MACD1[i-1]<0){Stat.SetTurn( i, 1);}
      if(MACD1[i]<0 && MACD1[i-1]>0){Stat.SetTurn( i, -1);}


      if(Stat.TurnPos()==NULL)continue;

      //---
      int i2nd=i1st+Inp2ndEmaPeriod+1;
      if(i<=i2nd)continue;

      double base=ATR[i]*InpThreshold;

      //--- high
      if((high[i]-base)>HSTEP[i-1]) HSTEP[i]=high[i];
      else if(high[i]+base<HSTEP[i-1]) HSTEP[i]=high[i]+base;
      else HSTEP[i]=HSTEP[i-1];
      //--- low
      if(low[i]+base<LSTEP[i-1]) LSTEP[i]=low[i];
      else if((low[i]-base)>LSTEP[i-1]) LSTEP[i]=low[i]-base;
      else LSTEP[i]=LSTEP[i-1];

      if(Stat.TurnPos()==i)
        {
         if(Stat.TurnDir()==  1 )  Stat.LastTop(i);
         if(Stat.TurnDir()== -1 )  Stat.LastBtm(i);


        }

      if(Stat.TurnDir()==1)
        {
         int lasttop=Stat.LastTop();
         if(high[i]>high[Stat.LastTop()]) Stat.LastTop(i);

         if(false && Stat.TurnPos()==i)
           {

            int imin=ArrayMinimum(low,i-(InpKeepPeriod-1),InpKeepPeriod);
            int imax=ArrayMaximum(high,imin+1,i-imin);
            UpSignal.Begin(imin, imax, 1);
            UpSignal.UpdateMax(imax,high[imax]);
            UP1[imin]=low[imin];

           }
         else if(stddev<MACD1[i] && 
            (MACD1[i]<MACD1SIG[i] && MACD1[i-1]>MACD1SIG[i-1]) && 
            lasttop>i-InpKeepPeriod
            )
              {
               int imin=ArrayMinimum(low,lasttop+1,i-lasttop);
               DnSignal.Begin(lasttop, imin, -2);
               DnSignal.UpdateMin(imin,low[imin]);
               DN1[lasttop]=high[lasttop];
              }
           }

         if(Stat.TurnDir()==-1)
           {
            int lastbtm=Stat.LastBtm();
            if(low[i]<low[Stat.LastBtm()]) Stat.LastBtm(i);

            if(false && Stat.TurnPos()==i)
              {

               int imax=ArrayMaximum(high,i-(InpKeepPeriod-1),InpKeepPeriod);
               int imin=ArrayMinimum(low,imax+1,i-imax);
               DnSignal.Begin(imax, imin, -1);
               DnSignal.UpdateMin(imin,low[imin]);
               DN1[imax]=high[imax];

              }
            else if(-stddev>MACD1[i] && 
               (MACD1[i]>MACD1SIG[i] && MACD1[i-1]<MACD1SIG[i-1]) && 
               lastbtm>i-InpKeepPeriod
               )
                 {

                  int imax=ArrayMaximum(high,lastbtm+1,i-lastbtm);
                  UpSignal.Begin(lastbtm, imax, 2);
                  UpSignal.UpdateMax(imax, high[imax]);
                  UP1[lastbtm]=low[lastbtm];

                 }
              }
            //---
            if(UpSignal.State()==2)
              {
               if(HSTEP[i]<=HSTEP[i-1])
                 {
                  UPPER[i]=HSTEP[i];
                 }
               else
                 {
                  UpSignal.Exit();
                  BUY[i]=low[i];
                 }
              }
            //---
            if(DnSignal.State()==2)
              {
               if(LSTEP[i]>=LSTEP[i-1])
                 {
                  LOWER[i]=LSTEP[i];
                 }
               else
                 {
                  SELL[i]=high[i];
                  DnSignal.Exit();
                 }
              }

            //---
            if(UpSignal.Sig()==2)
              {
               if(MACD1[i]<MACD1SIG[i])
                 {
                  if(InpUsingReversal)SELL[i]=high[i];
                  UpSignal.Exit();
                 }
              }
            //---
            else if(DnSignal.Sig()==-2)
              {
               if(MACD1[i]>MACD1SIG[i])
                 {
                  if(InpUsingReversal)BUY[i]=low[i];
                  DnSignal.Exit();
                 }
              }
            //---
            //---
            if(UpSignal.Sig()>0 && UpSignal.State()<2)
              {
               int x=UpSignal.ChkNextPos(high,low,close,i,ATR[i]);

               if(x>0)
                 {
                  if(UpSignal.State()==2)
                    {
                     UP2[x]=high[x];
                     HSTEP[i]=high[x];
                     UPPER[i]=high[x];
                    }
                 }
              }
            //---
            if(DnSignal.Sig()<0 && DnSignal.State()<2)
              {
               int x=DnSignal.ChkNextPos(high,low,close,i,ATR[i]);
               if(x>0)
                 {
                  if(DnSignal.State()==2)
                    {
                     DN2[x]=low[x];
                     LSTEP[i]=low[x];
                     LOWER[i]=low[x];
                    }
                 }
              }

           }

         //----

         return(rates_total);
        }
      //+------------------------------------------------------------------+

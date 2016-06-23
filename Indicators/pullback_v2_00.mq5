//+------------------------------------------------------------------+
//|                                               pullback_v1_11.mq5 |
//| pullback 1.11                             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"

#property indicator_buffers 16
#property indicator_plots  5
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


#property indicator_type5 DRAW_SECTION
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
   int               m_turn;
   int               m_turn_pos;
   datetime          m_old_time;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_turn=NULL;
      m_turn_pos=NULL;
      m_old_time=0;
 
     }
   int Turn() { return m_turn;}
   void SetTurn(int p,int v) {m_turn_pos=p;  m_turn=v;}
   int TurnPos() { return m_turn_pos;}
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

input int InpEma1Period=3;  //Fast EMA Period
input int InpEma2Period=20;  //Secound EMA Period

int AtrPeriod=100;      // ATR Period
double AtrAlpha=2.0/(AtrPeriod+1.0);

double Ema1Alpha=2.0/(InpEma1Period+1.0);
double Ema2Alpha=2.0/(InpEma2Period+1.0);

//---- will be used as indicator buffers
double EMA1[];
double EMA2[];

double ZZ[];
double ATR[];
double BUY[];
double SELL[];

double SIG1T[];
double SIG2T[];
double SIG3T[];
double SIG1B[];
double SIG2B[];
double SIG3B[];
double CNT[];

CStatus Stat;
CBuffer TurnBuffer;

//---- declaration of global variables

int min_rates_total=2;
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
   SetIndexBuffer(i++,ZZ,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG1T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG1B,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG2T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG2B,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG3T,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG3B,INDICATOR_DATA);
   SetIndexBuffer(i++,CNT,INDICATOR_DATA);
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
   Stat.Init();
   TurnBuffer.Init(100);
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
   if(!Stat.IsNewBar()) return rates_total;

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first<prev_calculated) first=prev_calculated-1;

//---
   for(int bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      i=bar-1;
      if(CNT[i]==1)continue;
      CNT[i]=1;

      ATR[bar]=EMPTY_VALUE;
      EMA1[bar]=EMPTY_VALUE;
      EMA2[bar]=EMPTY_VALUE;
      BUY[bar]=EMPTY_VALUE;
      SELL[bar]=EMPTY_VALUE;
      SIG1T[bar]=EMPTY_VALUE;
      SIG2T[bar]=EMPTY_VALUE;
      SIG3T[bar]=EMPTY_VALUE;
      SIG1B[bar]=EMPTY_VALUE;
      SIG2B[bar]=EMPTY_VALUE;
      SIG3B[bar]=EMPTY_VALUE;
      if(i==begin_pos)
        {
         // only first time
         ATR[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         EMA1[i]=close[i];
         EMA2[i]=close[i];

        }
      else
      {
         double atr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
         atr=fmax(ATR[i-1]*0.667,fmin(atr,ATR[i-1]*1.333));
         ATR[i]=AtrAlpha*atr+(1-AtrAlpha)*ATR[i-1];
         EMA1[i]=Ema1Alpha*EMA1[i]+(1-Ema1Alpha)*EMA1[i-1];
         EMA2[i]=Ema2Alpha*EMA2[i]+(1-Ema2Alpha)*EMA2[i-1];
      }
      
      //---

      int i1st=begin_pos+2;
      if(i<=i1st)continue;

      if(EMA1[i]>EMA2[i]+ATR[i] && EMA1[i-1]<EMA2[i-1]+ATR[i])
      {
         int x1=TurnBuffer.GetIndex(1);
         int imin=ArrayMinimum(low,x1,i-x1);
         ZZ[imin]=low[imin];
         TurnBuffer.Add(i,1);
      }
      else if(EMA1[i]<EMA2[i]-ATR[i] && EMA1[i-1]>EMA2[i-1]-ATR[i])
      {
         int x1=TurnBuffer.GetIndex(1);
         int imax=ArrayMaximum(high,x1,i-x1);
         ZZ[imax]=high[imax];
         TurnBuffer.Add(i,-1);
      }
      
      //---
      if(TurnBuffer.GetIndex(1)==NULL) continue;
      if(TurnBuffer.GetValue(0)==1 )
      {
      
      
      }
      if(TurnBuffer.GetValue(0)==-1)
      {
      
      }
      //---
      //---

     }

//----    

   return(rates_total);
  }

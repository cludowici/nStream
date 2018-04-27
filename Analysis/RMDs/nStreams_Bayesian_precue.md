nStreams Analysis: Precue Experiment
================
Charlie Ludowici
5/18/2017

``` r
library(ggplot2)
library(reshape2)
library(papaja)
theme_set(theme_apa(base_size = 15) ) 

savePlots <- F
nParticipants = 13

horizErrorBars <- function(data, var.name){
  SPEs <- data[,var.name]
  otherColumn <- colnames(data)[which(colnames(data)!=var.name & colnames(data) != 'participant' & colnames(data) != 'Parameter')]
  y = mean(data[,otherColumn], na.rm=T)
  se = sqrt(var(SPEs)/length(which(!is.na(SPEs))))
  xmin <- mean(SPEs, na.rm=T) - se
  xmax <- mean(SPEs, na.rm=T) + se
  x = mean(SPEs, na.rm=T)
  data.frame(x=x, xmin=xmin, xmax=xmax, y=y)
}

vertErrorBars <- function(data, var.name){
  SPEs <- data[,var.name]
  otherColumn <- colnames(data)[which(colnames(data)!=var.name & colnames(data) != 'participant' & colnames(data) != 'Parameter')]
  x = mean(data[,otherColumn], na.rm=T)
  se = sqrt(var(SPEs)/length(which(!is.na(SPEs))))
  ymin <- mean(SPEs, na.rm=T) - se
  ymax <- mean(SPEs, na.rm=T) + se
  y = mean(SPEs, na.rm=T)
  data.frame(x=x, ymin=ymin, ymax=ymax, y=y)
}


posterior <- function(t, N1, N2=NULL, delta, lo=-Inf, hi = Inf,
                      priorMean=0,priorSD=1) {
        N = ifelse(is.null(N2), N1, N1*N2/(N1+N2))
        df  = ifelse(is.null(N2), N1 - 1, N1 + N2 - 2)
        
        #prior and likelihood
        #prior <- function(delta) dnorm(delta, priorMean, priorSD)*as.integer(delta >= lo)*as.integer(delta <= hi) 
        prior <- function(delta) dcauchy(delta, priorMean, priorSD)*as.integer(delta >= lo)*as.integer(delta <= hi) 
        K=1/integrate(prior,lower=lo,upper=hi)[[1]]
        f=function(delta) K*prior(delta)
        
        #(The as.integer bits above just provide bounds for the prior if you want them)
      
        likelihood <- function(delta) dt(t, df, delta*sqrt(N))
        
        #marginal likelihood
        marginal <- integrate(function(x) f(x)*likelihood(x), lo, hi)[[1]]
        
        #posterior
        post <- function(x) f(x)*likelihood(x) / marginal
        return(post(delta))
}
```

``` r
null = 0

MMlatency <- read.csv('../modelOutput/precueCSV/TGRSVP_Exp2_LatencyNorm.csv')
MMprecision <- read.csv('../modelOutput/precueCSV/TGRSVP_Exp2_precisionNorm.csv')
MMefficacy <- read.csv('../modelOutput/precueCSV/TGRSVP_Exp2_efficacyNorm.csv')

latency <- data.frame(twoStreams = MMlatency$SingleLeft[MMlatency$Group == 1], eightStreams = MMlatency$SingleLeft[MMlatency$Group == 2])
latency <- latency[complete.cases(latency),]
latency$participant <- factor(1:nParticipants)

precision <- data.frame(twoStreams = MMprecision$SingleLeft[MMprecision$Group == 1], eightStreams = MMprecision$SingleLeft[MMprecision$Group == 2])
precision <- precision[complete.cases(precision),]
precision$participant <- factor(1:nParticipants)

efficacy <- data.frame(twoStreams = MMefficacy$SingleLeft[MMefficacy$Group == 1], eightStreams = MMefficacy$SingleLeft[MMefficacy$Group == 2])
efficacy <- efficacy[complete.cases(efficacy),]
efficacy$participant <- factor(1:nParticipants)

frequentistTestLatency = t.test(x = latency$eightStreams, y=latency$twoStreams, paired = T)
tLatency <- frequentistTestLatency$statistic[[1]]
frequentistTestLatency
```

    ## 
    ##  Paired t-test
    ## 
    ## data:  latency$eightStreams and latency$twoStreams
    ## t = 3.9875, df = 12, p-value = 0.001802
    ## alternative hypothesis: true difference in means is not equal to 0
    ## 95 percent confidence interval:
    ##  10.55607 35.98837
    ## sample estimates:
    ## mean of the differences 
    ##                23.27222

Latency Analyses
================

``` r
latencyForPlot <- melt(latency, measure.vars = c('twoStreams','eightStreams'),variable.name = 'Condition', value.name = 'Estimate')
latencyForPlot$Participant <- ordered(rep(1:nParticipants, times = 2))

t  <- tLatency
N1 <- nParticipants
N2 <- nParticipants

priorMean = null
priorSD = sqrt(.5)

#examples of BF via savage-dickey ratio
#2-sided
BF10 = dcauchy(null,priorMean,priorSD) / posterior(tLatency, N1, delta=null,
                                              priorMean=priorMean,priorSD=priorSD)

#one-sided BF
BFplus = ( 2 * dcauchy(null,priorMean,priorSD) ) / posterior(tLatency, N1, delta=null, lo=0,
                                            priorMean=priorMean,priorSD=priorSD)

BF10
```

    ## [1] 24.05731

``` r
BFplus
```

    ## [1] 48.03092

``` r
delta  <- seq(-2, 4, .01)

posteriorAndPriorDF <- data.frame(delta = delta, posterior = posterior(t,N1,delta=delta, priorMean=priorMean,priorSD=priorSD), prior = dcauchy(delta, priorMean,priorSD))

posteriorModeLatency <- optimize(function(delta) posterior(tLatency, N1, delta=delta, priorMean=priorMean, priorSD=priorSD), interval=c(-4,4),maximum = T)[[1]]

#This would only work for normal, we use Cauchy!
#credibleIntervalDensityLower <- mean(posteriorAndPriorDF$posterior)-sd(posteriorAndPriorDF$posterior)*1.96
#credibleIntervalDensityUpper <- mean(posteriorAndPriorDF$posterior)+sd(posteriorAndPriorDF$posterior)*1.96


latencyPlot <- ggplot(latencyForPlot,aes(x=Condition, y=Estimate))+
  geom_violin()+
  geom_line(aes(group=Participant, colour=Participant))+
  geom_point(aes(colour=Participant), size = 3)+
  scale_colour_brewer(palette = 'Spectral')+
  labs(x='Condition',y='Estimate (ms)',title='Latency')+
  theme(plot.title = element_text(hjust=.5))

show(latencyPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-29-1.png)

``` r
latencyHorizSE <- horizErrorBars(latency, 'twoStreams')
latencyVertSE <- vertErrorBars(latency, 'eightStreams')

latencyScatter <- ggplot(latency, aes(x=twoStreams, y=eightStreams))+
  geom_point(size = 4, aes(colour=participant))+
  scale_color_brewer(palette='Spectral', name='Participant')+
  geom_point(data = data.frame(x=mean(latency$twoStreams, na.rm=T), y = mean(latency$eightStreams, na.rm=T)), aes(x=x,y=y, shape = 'Mean'), size = 10, inherit.aes = F)+
  geom_errorbarh(data = latencyHorizSE, aes(x=x, xmin=xmin, xmax = xmax, y=y),inherit.aes = F, height=10)+
  geom_errorbar(data=latencyVertSE, aes(x=x, ymin=ymin,ymax=ymax, y=y), inherit.aes = F, width = 10)+
  scale_shape_manual(values=c('Mean' = 9), labels = NULL, name = "Mean")+
  lims(x=c(20,300), y=c(20,300))+
  labs(title='Latency Estimates (ms)', x = 'Two Streams', y='Eight Streams')+
  theme(plot.title = element_text(size=15, hjust=.5))+
  annotate('text', x=100, y=45, label = paste0('BF10 = ', round(BF10,2)))+
  annotate('text', x = 100, y=37, label = paste0('Effect size = ', round(posteriorModeLatency,2)))+
  geom_abline(intercept = 0, slope = 1,linetype='dashed')+
  coord_fixed()

show(latencyScatter)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-29-2.png)

``` r
latencyBayesPlot <- ggplot(posteriorAndPriorDF, aes(x=delta))+
  geom_line(aes(y=posterior, linetype = 'Posterior'))+
  geom_line(aes(y=prior, linetype = 'Prior'))+
  scale_linetype_manual(values = c('solid','dashed'),  guide = 'legend', name = NULL)+
  labs(x = expression(delta), y='Density', title = 'Latency Effect Size')

show(latencyBayesPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-29-3.png)

Precision Analysis
==================

``` r
precisionForPlot <- melt(precision, measure.vars = c('twoStreams','eightStreams'),variable.name = 'Condition', value.name = 'Estimate')
precisionForPlot$Participant <- ordered(rep(1:nParticipants, times = 2))


frequentistTestPrecision <- t.test(x = precision$eightStreams, y = precision$twoStreams, paired = T)
tPrecision <- frequentistTestPrecision$statistic[[1]]

t  <- tPrecision
N1 <- nParticipants
N2 <- nParticipants

priorMean =0
priorSD = sqrt(.5)

#examples of BF via savage-dickey ratio
#2-sided
BF10 = dcauchy(0,priorMean,priorSD) / posterior(tPrecision, N1, delta=0,
                                              priorMean=priorMean,priorSD=priorSD)

#one-sided BF
BFplus = ( 2 * dcauchy(0,priorMean,priorSD) ) / posterior(tPrecision, N1, delta=0, lo=0,
                                            priorMean=priorMean,priorSD=priorSD)

BF10
```

    ## [1] 0.3467804

``` r
BFplus
```

    ## [1] 0.1791612

``` r
delta  <- seq(-4, 2, .01)

posteriorModePrecision <- optimize(function(delta) posterior(tPrecision, N1, delta=delta,priorMean=priorMean,priorSD=priorSD), interval=c(-4,4),maximum = T)[[1]]

posteriorAndPriorDF <- data.frame(delta = delta, posterior = posterior(t,N1,delta=delta,
                                                                       priorMean=priorMean,priorSD=priorSD), prior = dcauchy(delta, priorMean,priorSD))

posteriorModePrecision <- optimize(function(delta) posterior(tPrecision, N1, delta=delta, priorMean=priorMean, priorSD=priorSD), interval=c(-4,4),maximum = T)[[1]]


precisionPlot <- ggplot(precisionForPlot,aes(x=Condition, y=Estimate))+
  geom_violin()+
  geom_line(aes(group=Participant, colour=Participant))+
  geom_point(aes(colour=Participant),alpha=.8, size = 3)+
  scale_colour_brewer(palette = 'Spectral')+
  labs(x='Condition',y='Estimate (ms)',title='Precision')+
  theme(plot.title = element_text(hjust=.5))

show(precisionPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-30-1.png)

``` r
precisionHorizSE <- horizErrorBars(precision, 'twoStreams')
precisionVertSE <- vertErrorBars(precision, 'eightStreams')


precisionScatter <- ggplot(precision, aes(x=twoStreams, y=eightStreams, colour = participant))+
  geom_point(size = 4)+
  scale_color_brewer(palette='Spectral', name='Participant')+
  geom_point(data = data.frame(x=mean(precision$twoStreams, na.rm=T), y = mean(precision$eightStreams, na.rm=T)), aes(x=x,y=y, shape = 'Mean'), size = 10, inherit.aes = F)+
  geom_errorbarh(data = precisionHorizSE, aes(x=x, xmin=xmin, xmax = xmax, y=y),inherit.aes = F, height=10)+
  geom_errorbar(data=precisionVertSE, aes(x=x, ymin=ymin,ymax=ymax, y=y), inherit.aes = F, width = 10)+
  scale_shape_manual(values=c('Mean' = 9), labels = NULL, name = "Mean")+
  lims(x=c(40,200), y=c(40,200))+
  labs(title='Precision Estimates (ms)')+
  theme(plot.title = element_text(size=15, hjust=.5))+
  annotate('text', x=170, y=70, label = paste0('BF10 = ', round(BF10,2)))+
  annotate('text', x = 170, y=60, label = paste0('Effect size = ', round(posteriorModePrecision,2)))+
  geom_abline(intercept = 0, slope = 1,linetype='dashed')+
  coord_fixed()

show(precisionScatter)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-30-2.png)

``` r
precisionBayesPlot <- ggplot(posteriorAndPriorDF, aes(x=delta))+
  geom_line(aes(y=posterior, linetype = 'Posterior'))+
  geom_line(aes(y=prior, linetype = 'Prior'))+
  scale_linetype_manual(values = c('solid','dashed'),  guide = 'legend', name = NULL)+
  labs(x = expression(delta), y='Density', title = 'Precision Effect Size')

show(precisionBayesPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-30-3.png)

Efficacy Analysis
=================

``` r
frequentistTestEfficacy <- t.test(x = efficacy$eightStreams, y = efficacy$twoStreams, paired = T)
tEfficacy <- frequentistTestEfficacy$statistic[[1]]

efficacyForPlot <- melt(efficacy, measure.vars = c('twoStreams','eightStreams'), variable.name = 'Condition',value.name = 'Estimate')
efficacyForPlot$Participant <- ordered(rep(1:nParticipants, times = 2))

t  <- tEfficacy
N1 <- nParticipants
N2 <- nParticipants

priorMean =0
priorSD = sqrt(.5)

#examples of BF via savage-dickey ratio
#2-sided
BF10 = dcauchy(0,priorMean,priorSD) / posterior(tEfficacy, N1, delta=0,
                                              priorMean=priorMean,priorSD=priorSD)

#one-sided BF
BFplus = ( 2 * dcauchy(0,priorMean,priorSD) ) / posterior(tEfficacy, N1, delta=0, lo=0,
                                            priorMean=priorMean,priorSD=priorSD)

BF10
```

    ## [1] 0.7606536

``` r
BFplus
```

    ## [1] 0.1260706

``` r
delta  <- seq(-2, 4, .01)

posteriorAndPriorDF <- data.frame(delta = delta, posterior = posterior(t,N1,delta=delta,
                                                                       priorMean=priorMean,priorSD=priorSD), prior = dcauchy(delta, priorMean,priorSD))

posteriorModeEfficacy <- optimize(function(delta) posterior(tEfficacy, N1, delta=delta,priorMean=priorMean,priorSD=priorSD), interval=c(-4,4),maximum = T)[[1]]


efficacyPlot <- ggplot(efficacyForPlot, aes(x=Condition, y=Estimate))+
  geom_violin()+
  geom_line(aes(group=Participant, colour=Participant))+
  geom_point(aes(colour = Participant), size = 3)+
  labs(x='Condition',y='Estimate',title='Efficacy')+
  theme(plot.title = element_text(hjust=.5))+
  scale_colour_brewer(palette = 'Spectral')

show(efficacyPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-31-1.png)

``` r
efficacyHorizSE <- horizErrorBars(efficacy, 'twoStreams')
efficacyVertSE <- vertErrorBars(efficacy, 'eightStreams')

efficacyScatter <- ggplot(efficacy, aes(x=twoStreams, y=eightStreams, colour=participant))+
  geom_point(size = 4)+
  scale_color_brewer(palette='Spectral', name='Participant')+
  geom_point(data = data.frame(x=mean(efficacy$twoStreams, na.rm=T), y = mean(efficacy$eightStreams, na.rm=T)), aes(x=x,y=y, shape = 'Mean'), size = 10, inherit.aes = F)+
  geom_errorbarh(data = efficacyHorizSE, aes(x=x, xmin=xmin, xmax = xmax, y=y),inherit.aes = F, height=.01)+
  geom_errorbar(data=efficacyVertSE, aes(x=x, ymin=ymin,ymax=ymax, y=y), inherit.aes = F, width = .01)+
  scale_shape_manual(values=c('Mean' = 9), labels = NULL, name = "Mean")+
  lims(x=c(0,1), y=c(0,1))+
  labs(title='Efficacy Estimates [1 - P(Guess)]', y = 'Eight Streams', y='Eight Streams')+
  theme(plot.title = element_text(size=15, hjust=.5))+
  annotate('text', x=.8, y=.45, label = paste0('BF10 = ', round(BF10,2)))+
  annotate('text', x = .8, y=.37, label = paste0('Effect size = ', round(posteriorModeEfficacy,2)))+
  geom_abline(intercept = 0, slope = 1,linetype='dashed')+
  coord_fixed()

show(efficacyScatter)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-31-2.png)

``` r
efficacyBayesPlot <- ggplot(posteriorAndPriorDF, aes(x=delta))+
  geom_line(aes(y=posterior, linetype = 'Posterior'))+
  geom_line(aes(y=prior, linetype = 'Prior'))+
  scale_linetype_manual(values = c('solid','dashed'),  guide = 'legend', name = NULL)+
  labs(x = expression(delta), y='Density', title = 'Efficacy Effect Size')

show(efficacyBayesPlot)
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-31-3.png)

``` r
efficacy$Parameter <- as.character('Efficacy')
latency$Parameter <- as.character('Latency')
precision$Parameter <- as.character('Precision')

allParams <- rbind(efficacy,latency,precision)

allParams <- melt(allParams, measure.vars = c('twoStreams','eightStreams'), variable.name = 'Condition',value.name = 'Estimate')

paramBar <- ggplot(allParams[!allParams$Parameter=='Efficacy',], aes(x=Parameter,y=Estimate, fill = Condition))+
  stat_summary(geom='bar', fun.y = mean, position = position_dodge(.9))+
  stat_summary(geom='errorbar', fun.data=mean_se, position = position_dodge(.9), width = .3)+
  scale_fill_brewer(palette = 'Spectral')

paramBar
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-32-1.png)

``` r
predictions <- data.frame(twoStreams = rnorm(1000, latency$twoStreams[7], precision$twoStreams[7]), eightStreams = rnorm(1000, latency$eightStreams[7], precision$eightStreams[7]))

predictions <- melt(predictions, measure.vars = c('twoStreams', 'eightStreams'), variable.name = 'Condition', value.name = 'response')

meanLatencyTwo <- mean(latency$twoStreams)
meanLatencyEight <- mean(latency$eightStreams)

meanPrecisionTwo <- mean(precision$twoStreams)
meanPrecisionEight <- mean(precision$eightStreams)


predictionPlot <- ggplot()+
  stat_function(data=data.frame(x=c(-400:400)/83.33), aes(x, fill = 'Two Streams'), fun = dnorm, args = list(mean = meanLatencyTwo/83.33, sd = meanPrecisionTwo/83.33), geom='area', alpha = .5)+
  stat_function(data=data.frame(x=c(-400:400)/83.33), aes(x, fill = 'Eight Streams'), fun = dnorm, args = list(mean = meanLatencyEight/83.33, sd = meanPrecisionEight/83.33), geom='area', alpha = .6)+
  scale_fill_brewer(palette = 'Set1')+
  scale_x_continuous(breaks = -3:4,limits = c(-3,4))+
  labs(x='SPE', y=NULL, fill = 'Condition')

predictionPlot
```

![](nStreams_Bayesian_precue_files/figure-markdown_github/unnamed-chunk-32-2.png)

``` r
if(savePlots){
  ggsave(precisionPlot, file = 'precisionViolin.png', height=15, width=20,units='cm')
  ggsave(latencyPlot, file = 'latencyViolin.png', height=15, width=20,units='cm')
  ggsave(efficacyPlot, file = 'efficacyViolin.png', height=15, width=20,units='cm')
  
  ggsave(precisionScatter, file = 'precisionScatter.png', height=15, width=20,units='cm')
  ggsave(latencyScatter, file = 'latencyScatter.png', height=15, width=20,units='cm')
  ggsave(efficacyScatter, file = 'efficacyScatter.png', height=15, width=20,units='cm')
  
  
  ggsave(efficacyBayesPlot, file = 'efficacyEffectSize.png', height=15, width=20,units='cm')
  ggsave(latencyBayesPlot, file = 'latencyEffectSize.png', height=15, width=20,units='cm')
    ggsave(precisionBayesPlot, file = 'precisionEffectSize.png', height=15, width=20,units='cm')
}
```
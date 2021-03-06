#' @title Simulate the finite sample critical values for the PSY test.
#'
#' @description \code{cvPSY} implements the real time bubble detection procedure
#'   of Phillips, Shi and Yu (2015a,b)
#'
#' @param obs   A positive integer. The number of observations.
#' @param swindow0 A positive integer. Minimum window size (default = \eqn{T
#'   (0.01 + 1.8/\sqrt{T})}, where \eqn{T} denotes the sample size)
#' @param IC  A positive integer. 0 for fixed lag order 1 for AIC and 2 for BIC
#'   (default = 0).
#' @param adflag  A positive integer. Lag order when IC=0; maximum number of
#'   lags when IC>0 (default = 0).
#' @param nrep A positive integer. Number of replications (default = 199).
#' @param useParallel Logical. If \code{useParallel=TRUE}, use multi core
#'   computation.
#' @param nCores A positive integer. Optional. If \code{useParallel=TRUE}, the
#'   number of cores defaults to all but one.
#'
#' @return A matrix. BSADF bootstrap critical value sequence at the 90, 95 and
#'   99 percent level.
#'
#' @references Phillips, P. C. B., Shi, S., & Yu, J. (2015a). Testing for
#'   multiple bubbles: Historical episodes of exuberance and collapse in the S&P
#'   500. \emph{International Economic Review}, 56(4), 1034--1078.
#' @references Phillips, P. C. B., Shi, S., & Yu, J. (2015b). Testing for
#'   multiple bubbles: Limit Theory for Real-Time Detectors. \emph{International
#'   Economic Review}, 56(4), 1079--1134.
#'
#' @export
#'
#' @import doParallel
#' @import parallel
#' @import foreach
#' @importFrom stats rnorm
#' @importFrom stats quantile
#'
#' @examples
#' \donttest{
#' cv <- cvPSY(100,  swindow0 = 90, IC = 0, adflag = 1, nrep = 199)
#' }

cvPSY <- function(obs, swindow0, IC=0, adflag=0, nrep=199,
                  useParallel=TRUE, nCores) {

  if (missing(swindow0)) {
    swindow0 <- floor(obs * (0.01 + 1.8 / sqrt(obs)))
  }

  qe <- as.matrix(c(0.90, 0.95, 0.99))
  m  <- nrep

  dim <- obs - swindow0 + 1

  SI <- 1
  set.seed(101)
  rnorm(SI)
  e <- replicate(m, rnorm(obs))
  a <- obs^(-1)
  z <- e + a
  y <- apply(z, 2, cumsum)

  # setup parallel backend
  if (useParallel == TRUE && missing(nCores)) {
    nCores <- detectCores() - 1
  } else {
    nCores <- 1
  }
  cl <- makeCluster(nCores)
  registerDoParallel(cl)

  i <- 0
  MPSY <- foreach(i = 1:m, .inorder = FALSE, .combine = rbind,
                  .export = "ADFRcpp") %dopar% {
    PSY(y[, i], swindow0, IC, adflag)
  }


  Q_PSY <- as.matrix(quantile(MPSY, qe), na.rm = TRUE)


  return(Q_PSY)
}

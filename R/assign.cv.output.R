#' Cross validation output
#'
#' The assign.cv.output function outputs the summary results and plots for the
#' cross validation done on the training dataset.
#'
#' The assign.cv.output function is suggested to run after the
#' assign.preprocess, assign.mcmc and assign.summary function. For the cross
#' validation, The Y argument in the assign.mcmc function is the output value
#' "trainingData_sub" from the assign.preprocess function.
#'
#' @param processed.data The list object returned from the assign.preprocess
#' function.
#' @param mcmc.pos.mean.trainingData The list object returned from the
#' assign.mcmc function. Notice that for cross validation, the Y argument in
#' the assign.mcmc function should be set as the training dataset.
#' @param trainingData The genomic measure matrix of training samples (i.g.,
#' gene expression matrix). The dimension of this matrix is probe number x
#' sample number. The default is NULL.
#' @param trainingLabel The list linking the index of each training sample to a
#' specific group it belongs to.
#' @param adaptive_B Logicals. If TRUE, the model adapts the
#' baseline/background (B) of genomic measures for the test samples. The
#' default is FALSE.
#' @param adaptive_S Logicals. If TRUE, the model adapts the signatures (S) of
#' genomic measures for the test samples. The default is FALSE.
#' @param mixture_beta Logicals. If TRUE, elements of the pathway activation
#' matrix are modeled by a spike-and-slab mixture distribution. The default is
#' TRUE.
#' @param outputDir The path to the directory to save the output files. The
#' path needs to be quoted in double quotation marks.
#' @return The assign.cv.output returns one .csv file containing one/multiple
#' pathway activity for each individual training samples, scatter plots of
#' pathway activity for each individual pathway in all the training samples,
#' and heatmap plots for the gene expression signatures for each individual
#' pathways.
#' @author Ying Shen
#' @examples
#'
#' \dontshow{
#' tempdir <- file.path(tempdir(), "assign_cv_output")
#' data(trainingData1)
#' data(testData1)
#' data(geneList1)
#'
#' trainingLabel1 <- list(control = list(bcat=1:10, e2f3=1:10, myc=1:10,
#'                                       ras=1:10, src=1:10),
#'                        bcat = 11:19, e2f3 = 20:28, myc= 29:38,
#'                        ras = 39:48, src = 49:55)
#'
#' processed.data <- assign.preprocess(trainingData=trainingData1,
#' testData=testData1, trainingLabel=trainingLabel1, geneList=geneList1)
#' mcmc.chain <- assign.mcmc(Y=processed.data$trainingData_sub,
#' Bg = processed.data$B_vector, X=processed.data$S_matrix,
#' Delta_prior_p = processed.data$Pi_matrix, iter = 20, adaptive_B=TRUE,
#' adaptive_S=FALSE, mixture_beta=TRUE)
#' mcmc.pos.mean <- assign.summary(test=mcmc.chain, burn_in=10, iter=20,
#' adaptive_B=FALSE, adaptive_S=FALSE, mixture_beta=TRUE)
#' }
#' assign.cv.output(processed.data=processed.data,
#'                  mcmc.pos.mean.trainingData=mcmc.pos.mean,
#'                  trainingData=trainingData1,
#'                  trainingLabel=trainingLabel1,
#'                  adaptive_B=FALSE, adaptive_S=FALSE,
#'                  mixture_beta=TRUE, outputDir=tempdir)
#'
#' @export assign.cv.output
assign.cv.output <- function(processed.data, mcmc.pos.mean.trainingData,
                             trainingData, trainingLabel, adaptive_B=FALSE,
                             adaptive_S=FALSE, mixture_beta=TRUE, outputDir) {
  message("Outputing results...")

  if (mixture_beta) {
    coef_train <- mcmc.pos.mean.trainingData$kappa_pos
  } else {
    coef_train <- mcmc.pos.mean.trainingData$beta_pos
  }

  if (!dir.exists(outputDir)) {
    dir.create(outputDir)
  }

  rownames(coef_train) <- names(processed.data$trainingData_sub)
  colnames(coef_train) <- names(trainingLabel)[-1]

  if (any(file.exists(
    file.path(outputDir, "pathway_activity_trainingset.csv"),
    file.path(outputDir, "signature_heatmap_trainingset.pdf"),
    file.path(outputDir, "pathway_activity_scatterplot_trainingset.pdf")))) {
    stop("Output files already exist. Delete the following files to run assign.cv.output():\n",
         file.path(outputDir, "pathway_activity_trainingset.csv"), "\n",
         file.path(outputDir, "signature_heatmap_trainingset.pdf"), "\n",
         file.path(outputDir, "pathway_activity_scatterplot_trainingset.pdf"))
  }

  utils::write.csv(coef_train, file = file.path(outputDir, "pathway_activity_trainingset.csv"))

  #heatmaps of each pathway
  heatmap.train(diffGeneList = processed.data$diffGeneList, trainingData,
                trainingLabel, outPath = file.path(outputDir, "signature_heatmap_trainingset.pdf"))

  #provide test labels for model validation
  scatter.plot.train(coef_train, trainingData, trainingLabel,
                     outPath = file.path(outputDir, "pathway_activity_scatterplot_trainingset.pdf"))

}

# INTERNAL FUNCTIONS#
CV_calculation = function(vector) {
    value = sd(vector)/mean(vector)
    return(value)
}

CV_features = function(vector, CV_th) {
    features_15 = round(sum(vector < 0.5*CV_th)/length(vector), 2)
    features_30 = round(sum(vector < CV_th)/length(vector), 2)
    all_features = c(features_15, features_30)
    return(all_features)
}


# EXTERNAL FUNCTIONS#

## QC_CV##
QC_CV = function(QCmetabo_matrix, metabo_ids = NULL, CV_th = 0.30, plot_hist = TRUE,
                 hist_bw = 0.005, hist_col = "moccasin", size_lab = 12, size_axis = 12) {

    ## Check that input data are correct

    if (!is.matrix(QCmetabo_matrix) | !is.numeric(QCmetabo_matrix)) {
        stop("QCmetabo_matrix needs to be a numeric matrix")
    }
    cols_metabo = split(t(QCmetabo_matrix), row(t(QCmetabo_matrix)))
    CV_metabo = sapply(cols_metabo, CV_calculation)
    CV_metabo = abs(CV_metabo) # absolute value of CV

    if (length(CV_metabo) == length(metabo_ids)) {
        names(CV_metabo) = metabo_ids
    }

    features_CV_metabo = CV_features(CV_metabo, CV_th = CV_th)

    if (is.na(features_CV_metabo[1])) {
        stop("CV calculation failed: please check QCmetabo_matrix")
    }

    message("CV summary:")
    to_print = paste("   % metabolite features with CV <", 0.5*CV_th,":",
                     100 * features_CV_metabo[1], sep = " ")
    message(to_print)
    to_print = paste("   % metabolite features with CV <", CV_th,":",
                     100 * features_CV_metabo[2], sep = " ")
    message(to_print, "\n")

    ## Set max CV = 1
    CV_metabo_backup = CV_metabo

    if (plot_hist == TRUE) {
        CV_metabo[CV_metabo>1] = 1
       figure = ggplot(as.data.frame(CV_metabo), aes(CV_metabo)) +
       geom_histogram(fill = hist_col[1], binwidth = hist_bw,
                      colour = "black") + theme_bw() + labs(x = "CV", y = "count") +
       theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
               axis.text = element_text(size = size_axis), axis.title = element_text(size = size_lab),
               axis.title.y = element_text(vjust = 0), axis.title.x = element_text(vjust = 0))
       plot(figure)
    }
    return(CV_metabo_backup)
}

## QC_CV_specNMR ##

QC_CV_specNMR = function(metabo_vector, ppm, CV_metabo, CV_th = 0.30, xlab = "ppm",
                         ylab = "intensity", size_axis = 12, size_lab = 12,
                         xlim = NULL, ylim = NULL, xbreaks = waiver(),
                         xnames = waiver(), ybreaks = waiver(), ynames = waiver()) {

    ## Check that input data are correct
    if ((is.vector(CV_metabo) & is.vector(ppm) & is.vector(metabo_vector)) ==
        FALSE) {
        stop("Arguments: CV_metabo, metabo_vector and ppm, must be numeric vectors")
    }
    if (length(CV_metabo) != length(ppm) | length(CV_metabo) !=
        length(metabo_vector)) {
        stop("Arguments: CV_metabo, metabo_vector and ppm, must have the same length")
    }
    if (!is.numeric(ppm)) {
      stop ("ppm must be a numeric vector")
    }

    ## Create a NMR spectrum colored by CV

    abs.CV = CV_metabo
    abs.CV[abs.CV >= CV_th] = CV_th

    data_CV = data.frame(ppm = ppm, metabo_vector = metabo_vector, abs.CV = abs.CV,
                         CV_raw = CV_metabo)
    #color_scale = c("dodgerblue2", "green3", "gold", "darkorange2","orangered2", "red1")
    color_scale = c("green3","dodgerblue2","plum2","purple","purple4","red1")
    col_values = c(0, 0.45, 0.55,0.9, 0.9996666, 1)

    #options(warn = -1)

    figure_spectrum = ggplot(data_CV, aes(ppm, metabo_vector, color = abs.CV)) +
      geom_line() +
      scale_colour_gradientn(colours = color_scale, values = col_values,
                             space = "Lab", limits = c(0, CV_th),
                             breaks = c(0, CV_th/2, CV_th)) +
      scale_x_reverse(limits = xlim, breaks = xbreaks, labels = xnames) +
      scale_y_continuous(limits = ylim, breaks = ybreaks, labels = ynames) +
      theme_bw() +
      labs(x = xlab, y = ylab) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            axis.text = element_text(size = size_axis),
            axis.title = element_text(size = size_lab, vjust = 0))

    plot(figure_spectrum)

    #options(warn = 0)

    return(figure_spectrum)
}

## CV_filter ##
CV_filter = function (metabo_matrix, CV_metabo, CV_th = 0.30) {

    ## Check that input data are correct

    if (!is.matrix(metabo_matrix) | !is.numeric(metabo_matrix)) {
        stop("metabo_matrix needs to be a numeric matrix")
    }

    if (!is.vector(CV_metabo)) {
        stop("CV_metabo needs to be a numeric")
    }

    if (ncol(metabo_matrix) != length(CV_metabo)) {
        stop ("CV_metabo length must be consistent with metabo_matrix dimension")
    }

    if (is.numeric(CV_th) == FALSE) {
        stop ("CV_th must be a numeric value")
    }

    index_wanted = which(CV_metabo < CV_th)

    if(length(index_wanted) > 0) {
        metabo_matrix = metabo_matrix[,index_wanted]
        return (metabo_matrix)
    } else {
       stop ("None of the metabolic features meets the filtering criteria")
    }
}




# 📐 MoonLabelKit Statistical Theory & Mathematical Foundations

This guide outlines the exact mathematical definitions and algorithmic foundations implemented within **MoonLabelKit** (`@stats` and `@agreement` packages).

---

## 1. Inter-Annotator Agreement (Cohen's Kappa & Fleiss' Kappa)

### 1.1 Cohen's Kappa ($\kappa$) - Pairwise Agreement
Used to evaluate the agreement between exactly **two annotators** (`Annotator A` and `Annotator B`) across $N$ mutual categorical samples:
$$\kappa = \frac{P_o - P_e}{1 - P_e}$$
Where:
- **Observed Agreement ($P_o$)**:
  $$P_o = \frac{1}{N} \sum_{i=1}^N \mathbb{I}(y_i^{(A)} == y_i^{(B)})$$
- **Expected Agreement ($P_e$)**:
  $$P_e = \sum_{k \in K} P(y^{(A)} = k) \cdot P(y^{(B)} = k)$$

#### Interpretation Scale (Landis & Koch, 1977):
| $\kappa$ Value | Interpretation |
| :---: | :--- |
| $< 0.0$ | Poor / Systematic Disagreement |
| $0.0 - 0.2$ | Slight Agreement |
| $0.2 - 0.4$ | Fair Agreement |
| $0.4 - 0.6$ | Moderate Agreement |
| $0.6 - 0.8$ | Substantial Agreement |
| $0.8 - 1.0$ | Almost Perfect / Excellent Agreement |

---

### 1.2 Fleiss' Kappa ($\bar{\kappa}$) - Multi-Annotator Agreement
Extends Cohen's Kappa to evaluate agreement across **multiple annotators** ($n_i \ge 2$) who independently rate $M$ categorical samples into $K$ mutually exclusive categories.

For sample $i$, let $n_{ij}$ denote the number of annotators assigning category $j$:
$$\bar{P}_i = \frac{1}{n_i(n_i - 1)} \sum_{j=1}^K n_{ij}(n_{ij} - 1)$$

Mean observed agreement across all samples:
$$\bar{P} = \frac{1}{M} \sum_{i=1}^M \bar{P}_i$$

Expected chance agreement:
$$\bar{P}_e = \sum_{j=1}^K p_j^2, \quad \text{where } p_j = \frac{\sum_{i=1}^M n_{ij}}{\sum_{i=1}^M n_i}$$

Finally, Fleiss' Kappa is computed as:
$$\bar{\kappa} = \frac{\bar{P} - \bar{P}_e}{1 - \bar{P}_e}$$

---

## 2. Label Distribution Analysis (`@stats`)

### 2.1 Shannon Information Entropy ($H$)
Quantifies the uncertainty and diversity of the class label distribution across $C$ unique categories:
$$H(X) = - \sum_{i=1}^C p_i \log_2(p_i)$$
Higher entropy indicates a well-balanced dataset where samples are uniformly distributed across classes.

### 2.2 Gini Imbalance Coefficient ($G$)
Measures structural inequality across category frequencies:
$$G = \frac{\sum_{i=1}^C \sum_{j=1}^C |f_i - f_j|}{2 \cdot C \cdot \sum_{i=1}^C f_i}$$
Where $f_i$ is the absolute count of annotations for class $i$. $G \to 0$ indicates perfect balance, while $G \to 1$ indicates extreme long-tail class imbalance requiring data augmentation.

# Source: https://github.com/jupyter-incubator/sparkmagic/blob/master/Dockerfile.jupyter
# TODO: Using old version due https://github.com/jupyter-incubator/sparkmagic/issues/492
FROM jupyter/base-notebook:4a112c0f11eb

ARG dev_mode=false

USER root

# This is needed because requests-kerberos fails to install on debian due to missing linux headers
RUN conda install requests-kerberos -y

USER $NB_USER

RUN pip install --upgrade pip
RUN pip install --upgrade --ignore-installed setuptools

# COPY examples /home/jovyan/work

# Install sparkmagic - if DEV_MODE is set, use the one in the host directory.
# Otherwise, just install from pip.
# COPY hdijupyterutils hdijupyterutils/
# COPY autovizwidget autovizwidget/
# COPY sparkmagic sparkmagic/

USER root
RUN chown -R $NB_USER .

USER $NB_USER
RUN if [ "$dev_mode" = "true" ]; then \
      cd hdijupyterutils && pip install . && cd ../ && \
      cd autovizwidget && pip install . && cd ../ && \
      cd sparkmagic && pip install . && cd ../ ; \
    else pip install sparkmagic ; fi

RUN mkdir /home/$NB_USER/.sparkmagic
COPY sparkmagic.json /home/$NB_USER/.sparkmagic/config.json
# RUN sed -i 's/localhost/spark/g' /home/$NB_USER/.sparkmagic/config.json
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension
RUN jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel
RUN jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel
RUN jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkrkernel
RUN jupyter serverextension enable --py sparkmagic

USER root
RUN chown $NB_USER /home/$NB_USER/.sparkmagic/config.json
RUN rm -rf hdijupyterutils/ autovizwidget/ sparkmagic/

# Kamu magics
ADD kamu.py /opt/conda/lib/python3.8/site-packages/kamu.py

CMD ["start-notebook.sh", "--NotebookApp.iopub_data_rate_limit=1000000000"]

USER $NB_USER